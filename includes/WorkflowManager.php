class WorkflowManager {
    private $max_iterations;
    private $iteration_limit;
    private $llm_handler;
    private $logger;
    private $database;
    private $analytics;
    private $security;

    public function __construct() {
        $this->load_settings();
        $this->llm_handler = new LLMHandler();
        $this->logger = Logger::get_instance();
        $this->database = Database::get_instance();
        $this->analytics = new Analytics();
        $this->security = new Security();
    }

    private function load_settings() {
        $settings = Settings::get_instance();
        $this->max_iterations = $settings->get('max_iterations', 5);
        $this->iteration_limit = $settings->get('iteration_limit', 3);
    }

    public function run_workflow($prompt, $language = 'python') {
        try {
            $entry_id = $this->database->create_entry([
                'prompt' => $prompt,
                'language' => $language,
                'status' => 'processing'
            ]);

            $this->logger->info("Starting workflow for entry $entry_id with prompt: $prompt");

            $start_time = microtime(true);
            
            $code = $this->llm_handler->generate_code($prompt, $language);
            $iteration = 0;
            $bug_free = false;

            do {
                $bug_report = $this->llm_handler->check_bugs($code);
                $bug_free = $this->is_bug_free($bug_report);
                
                if (!$bug_free) {
                    $code = $this->llm_handler->apply_fixes($code, $bug_report);
                }

                $iteration++;
                
            } while (!$bug_free && $iteration < $this->max_iterations);

            $duration = microtime(true) - $start_time;
            $this->database->update_entry($entry_id, [
                'generated_code' => $code,
                'bug_reports' => $bug_report,
                'status' => 'completed',
                'completed_at' => current_time('mysql')
            ]);

            $this->analytics->log_completion($entry_id, $duration, $iteration);

            return [
                'code' => $code,
                'iterations' => $iteration,
                'duration' => $duration
            ];

        } catch (Exception $e) {
            $this->logger->error("Workflow failed: " . $e->getMessage());
            $this->database->update_entry($entry_id, [
                'status' => 'failed',
                'error' => $e->getMessage()
            ]);
            throw $e;
        }
    }

    public function generate_feature_enhanced_code($prompt, $features, $language = 'python') {
        try {
            $entry_id = $this->database->create_entry([
                'prompt' => $prompt,
                'features' => wp_json_encode($features),
                'language' => $language,
                'status' => 'processing'
            ]);

            $this->logger->info("Starting feature-enhanced workflow for entry $entry_id with prompt: $prompt");

            $start_time = microtime(true);
            
            $code = $this->llm_handler->generate_code($prompt, $language);
            $iteration = 0;
            $feature_index = 0;

            do {
                $bug_report = $this->llm_handler->check_bugs($code);
                $bug_free = $this->is_bug_free($bug_report);
                
                if (!$bug_free) {
                    $code = $this->llm_handler->apply_fixes($code, $bug_report);
                }

                if ($iteration % $this->iteration_limit === 0 && $feature_index < count($features)) {
                    $code = $this->apply_feature($code, $features[$feature_index], $language);
                    $feature_index++;
                }

                $iteration++;
                
            } while ($iteration < $this->max_iterations);

            $duration = microtime(true) - $start_time;
            $this->database->update_entry($entry_id, [
                'generated_code' => $code,
                'bug_reports' => $bug_report,
                'status' => 'completed',
                'completed_at' => current_time('mysql')
            ]);

            $this->analytics->log_completion($entry_id, $duration, $iteration, $feature_index);

            return [
                'code' => $code,
                'iterations' => $iteration,
                'features_implemented' => $feature_index,
                'duration' => $duration
            ];

        } catch (Exception $e) {
            $this->logger->error("Feature-enhanced workflow failed: " . $e->getMessage());
            $this->database->update_entry($entry_id, [
                'status' => 'failed',
                'error' => $e->getMessage()
            ]);
            throw $e;
        }
    }

    private function is_bug_free($bug_report) {
        return trim($bug_report) === '';
    }

    private function apply_feature($code, $feature, $language) {
        $model = $this->llm_handler->select_model('feature');
        $prompt = "Add the following feature to the existing code:\n\nFeature: $feature\n\nExisting code:\n" . $code;
        return $this->llm_handler->call_llm_api($model, $prompt, 'apply_feature', $language);
    }
}