class LLMHandler {
    private $api_keys;
    private $models;
    private $rate_limits;
    private $cache;
    private $security;

    public function __construct() {
        $this->load_settings();
        $this->initialize_cache();
        $this->security = new Security();
    }

    private function load_settings() {
        $this->api_keys = get_option('adversarial_llm_api_keys', []);
        $this->models = get_option('adversarial_llm_models', [
            'generation' => ['claude', 'gemini'],
            'checking' => ['claude', 'gemini'],
            'fixing' => ['claude']
        ]);
        $this->rate_limits = get_option('adversarial_llm_rate_limits', [
            'claude' => ['calls_per_minute' => 60, 'tokens_per_minute' => 10000],
            'gemini' => ['calls_per_minute' => 60, 'tokens_per_minute' => 10000]
        ]);
    }

    public function generate_code($prompt, $language = 'python') {
        try {
            $model = $this->select_model('generation');
            $prompt = $this->security->sanitize_prompt($prompt);
            return $this->call_llm_api($model, $prompt, 'generate', $language);
        } catch (Exception $e) {
            $this->logger->error('Code generation failed: ' . $e->getMessage());
            throw $e;
        }
    }

    public function check_bugs($code) {
        $bug_reports = [];
        foreach ($this->models['checking'] as $model_id) {
            try {
                $model = $this->get_model_config($model_id);
                $sanitized_code = $this->security->sanitize_code($code);
                $bug_report = $this->call_llm_api($model, $sanitized_code, 'check_bugs');
                $bug_reports[] = $this->parse_bug_report($bug_report);
            } catch (Exception $e) {
                $this->logger->warning('Bug checking failed for model ' . $model_id . ': ' . $e->getMessage());
            }
        }
        return $this->aggregate_bug_reports($bug_reports);
    }

    private function select_model($type) {
        $models = $this->models[$type];
        $strategy = get_option('adversarial_llm_rotation_strategy', 'round_robin');
        
        switch ($strategy) {
            case 'round_robin':
                $index = get_transient('adversarial_llm_' . $type . '_index') ?: 0;
                $model_id = $models[$index];
                $new_index = ($index + 1) % count($models);
                set_transient('adversarial_llm_' . $type . '_index', $new_index, HOUR_IN_SECONDS);
                break;
            case 'random':
                $model_id = $models[array_rand($models)];
                break;
            case 'weighted':
                $weights = get_option('adversarial_llm_weights', []);
                $model_id = $this->weighted_random_choice($models, $weights);
                break;
            default:
                $model_id = $models[0];
        }
        
        return $this->get_model_config($model_id);
    }

    private function weighted_random_choice($models, $weights) {
        $total_weight = array_sum($weights);
        $rand = mt_rand() / mt_getrandmax() * $total_weight;
        $current_weight = 0;
        
        foreach ($models as $model) {
            $current_weight += isset($weights[$model]) ? $weights[$model] : 1;
            if ($rand <= $current_weight) {
                return $model;
            }
        }
        
        return $models[count($models) - 1];
    }

    private function call_llm_api($model, $input, $action, $language = 'python') {
        // Check rate limits
        $this->check_rate_limits($model['id']);

        // Check cache
        $cache_key = $this->generate_cache_key($model['id'], $input, $action, $language);
        if ($cached_response = $this->cache->get($cache_key)) {
            $this->logger->info('Cache hit for ' . $cache_key);
            return $cached_response;
        }

        // Prepare request
        $args = [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->api_keys[$model['id']],
                'Content-Type' => 'application/json',
                'User-Agent' => 'WordPress/' . get_bloginfo('version') . '; ' . home_url('/')
            ],
            'body' => json_encode([
                'prompt' => $input,
                'action' => $action,
                'temperature' => isset($model['temperature']) ? $model['temperature'] : 0.7,
                'max_tokens' => isset($model['max_tokens']) ? $model['max_tokens'] : 2000,
                'language' => $language
            ]),
            'timeout' => 30
        ];

        // Make API request
        $response = wp_remote_post($model['endpoint'], $args);

        // Handle response
        if (is_wp_error($response)) {
            throw new Exception('API request failed: ' . $response->get_error_message());
        }

        $body = wp_remote_retrieve_body($response);
        $data = json_decode($body, true);

        if (isset($data['error'])) {
            throw new Exception('API error: ' . $data['error']);
        }

        // Cache response
        $this->cache->set($cache_key, $data['result'], 3600); // Cache for 1 hour

        // Update rate limiting stats
        $this->update_rate_limits($model['id'], strlen($input) + strlen($data['result']));

        // Log the API call
        $this->logger->info('API call to ' . $model['id'] . ' for action ' . $action);

        return $data['result'];
    }

    private function generate_cache_key($model_id, $input, $action, $language) {
        return 'adversarial_llm_' . md5($model_id . $input . $action . $language);
    }

    private function check_rate_limits($model_id) {
        $rate_limits = get_transient('adversarial_llm_rate_limits');
        if (!$rate_limits) {
            $rate_limits = [];
        }

        if (!isset($rate_limits[$model_id])) {
            $rate_limits[$model_id] = ['calls' => 0, 'tokens' => 0];
        }

        $model_rate_limits = $this->rate_limits[$model_id];
        if ($rate_limits[$model_id]['calls'] >= $model_rate_limits['calls_per_minute'] || 
            $rate_limits[$model_id]['tokens'] >= $model_rate_limits['tokens_per_minute']) {
            throw new Exception('Rate limit exceeded for model ' . $model_id);
        }

        set_transient('adversarial_llm_rate_limits', $rate_limits, MINUTE_IN_SECONDS);
    }

    private function update_rate_limits($model_id, $tokens_used) {
        $rate_limits = get_transient('adversarial_llm_rate_limits');
        if (!$rate_limits) {
            $rate_limits = [];
        }

        if (!isset($rate_limits[$model_id])) {
            $rate_limits[$model_id] = ['calls' => 0, 'tokens' => 0];
        }

        $rate_limits[$model_id]['calls']++;
        $rate_limits[$model_id]['tokens'] += $tokens_used;

        set_transient('adversarial_llm_rate_limits', $rate_limits, MINUTE_IN_SECONDS);
    }

    private function parse_bug_report($report) {
        // Implement parsing logic based on expected format from LLM
        return $report;
    }

    private function aggregate_bug_reports($reports) {
        // Implement aggregation logic
        return implode("\n\n", $reports);
    }
}