class Settings {
    private static $instance;
    private $options;

    private function __construct() {
        $this->options = get_option('adversarial_settings', []);
        $this->register_settings();
    }

    public static function get_instance() {
        if (!self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function register_settings() {
        register_setting('adversarial_settings', 'adversarial_settings');
    }

    public function get($key, $default = null) {
        return isset($this->options[$key]) ? $this->options[$key] : $default;
    }

    public function update($key, $value) {
        $this->options[$key] = $value;
        update_option('adversarial_settings', $this->options);
    }

    public function get_all() {
        return $this->options;
    }

    public function get_llm_api_keys() {
        return isset($this->options['llm_api_keys']) ? $this->options['llm_api_keys'] : [];
    }

    public function get_llm_models() {
        return isset($this->options['llm_models']) ? $this->options['llm_models'] : [
            'generation' => ['claude', 'gemini'],
            'checking' => ['claude', 'gemini'],
            'fixing' => ['claude']
        ];
    }

    public function get_max_iterations() {
        return isset($this->options['max_iterations']) ? (int)$this->options['max_iterations'] : 5;
    }

    public function get_iteration_limit() {
        return isset($this->options['iteration_limit']) ? (int)$this->options['iteration_limit'] : 3;
    }
}