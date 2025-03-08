class PublicUI {
    public function __construct() {
        add_action('wp_enqueue_scripts', [$this, 'enqueue_assets']);
    }

    public function enqueue_assets() {
        wp_enqueue_style('adversarial-public-style', plugins_url('assets/css/style.css', __FILE__));
        wp_enqueue_script('adversarial-public-script', plugins_url('assets/js/script.js', __FILE__), ['jquery'], ADVERSARIAL_VERSION, true);
        
        // Add code highlighting library
        wp_enqueue_script('prism-js', plugins_url('assets/js/prism.js', __FILE__), [], ADVERSARIAL_VERSION, true);
        wp_enqueue_style('prism-css', plugins_url('assets/css/prism.css', __FILE__), [], ADVERSARIAL_VERSION);
    }
}