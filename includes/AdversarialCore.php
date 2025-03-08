class AdversarialCore {
    private static $instance;
    public $settings;
    public $logger;
    public $workflow_manager;

    private function __construct() {
        $this->settings = new Settings();
        $this->logger = new Logger();
        $this->workflow_manager = new WorkflowManager();
        
        // Initialize other components
        $this->setup_actions();
    }

    public static function get_instance() {
        if (!self::$instance) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function setup_actions() {
        // Add any necessary actions/filters
        add_action('init', [$this, 'init']);
        add_action('rest_api_init', [$this, 'register_rest_routes']);
    }

    public function init() {
        // Initialization tasks
        load_plugin_textdomain('adversarial-code-generator', false, dirname(plugin_basename(__FILE__)) . '/languages/');
    }

    public function register_rest_routes() {
        // Register REST API routes
        register_rest_route('adversarial-code-generator/v1', '/generate', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [$this, 'rest_generate_code'],
            'permission_callback' => function() {
                return current_user_can('edit_posts');
            }
        ]);
    }

    public function rest_generate_code($request) {
        try {
            $prompt = $request->get_param('prompt');
            $features = $request->get_param('features') ?: [];
            $language = $request->get_param('language') ?: 'python';
            
            $workflow = AdversarialCore::get_instance()->workflow_manager;
            
            if (!empty($features)) {
                $result = $workflow->generate_feature_enhanced_code($prompt, $features, $language);
            } else {
                $result = $workflow->run_workflow($prompt, $language);
            }
            
            return new WP_REST_Response([
                'code' => $result['code'],
                'iterations' => $result['iterations'],
                'duration' => $result['duration'],
                'features_implemented' => isset($result['features_implemented']) ? $result['features_implemented'] : 0
            ], 200);
            
        } catch (Exception $e) {
            return new WP_REST_Response([
                'error' => $e->getMessage()
            ], 500);
        }
    }
}