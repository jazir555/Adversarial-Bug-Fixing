class CodeExecutionTimeout {
    public function __construct() {
        add_filter('adversarial_code_execution_timeout', [$this, 'get_execution_timeout']);
        add_action('admin_init', [$this, 'register_settings']);
    }

    public function register_settings() {
        register_setting('adversarial_settings', 'adversarial_code_execution_timeout');
    }

    public function get_execution_timeout($default = 30) {
        $timeout = get_option('adversarial_code_execution_timeout');
        return $timeout ? $timeout : $default;
    }
}