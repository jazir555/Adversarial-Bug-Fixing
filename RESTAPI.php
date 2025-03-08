class RESTAPI {
    public function __construct() {
        add_action('rest_api_init', [$this, 'register_routes']);
    }

    public function register_routes() {
        register_rest_route('adversarial-code-generator/v1', '/generate', [
            'methods' => WP_REST_Server::CREATABLE,
            'callback' => [$this, 'generate_code'],
            'permission_callback' => function() {
                return current_user_can('edit_posts');
            }
        ]);
    }

    public function generate_code($request) {
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