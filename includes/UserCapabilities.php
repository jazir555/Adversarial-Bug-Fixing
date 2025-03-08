class UserCapabilities {
    public function __construct() {
        add_action('admin_init', [$this, 'register_capabilities']);
    }
    
    public function register_capabilities() {
        $roles = get_editable_roles();
        
        foreach ($roles as $role_name => $role) {
            if ($role_name === 'administrator') {
                $this->add_capabilities_to_role($role_name);
            }
        }
    }
    
    private function add_capabilities_to_role($role_name) {
        $role = get_role($role_name);
        
        if (!$role) {
            return;
        }
        
        $capabilities = [
            'manage_code_generator_settings',
            'view_code_analytics',
            'execute_generated_code',
            'view_code_history',
            'manage_code_templates',
            'view_code_documentation',
            'generate_code',
            'access_code_editor',
            'participate_in_collaboration',
            'view_code_performance',
            'format_code',
            'translate_code',
            'share_code',
            'manage_code_snippets',
            'access_private_llms',
            'switch_theme',
            'view_code_sharing',
            'manage_code_environments',
            'manage_ci_pipelines',
            'view_code_analysis',
            'access_onboarding_tutorial',
            'refactor_code'
        ];
        
        foreach ($capabilities as $capability) {
            $role->add_cap($capability);
        }
    }
}