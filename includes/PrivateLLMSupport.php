class PrivateLLMSupport {
    public function __construct() {
        add_action('admin_init', [$this, 'register_settings']);
    }

    public function register_settings() {
        register_setting('adversarial_settings', 'adversarial_private_llms');
    }

    public function get_private_llms() {
        return get_option('adversarial_private_llms', []);
    }
}