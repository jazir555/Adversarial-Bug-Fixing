class AdminUI {
    public function __construct() {
        add_action('admin_menu', [$this, 'add_admin_menu']);
    }

    public function add_admin_menu() {
        add_menu_page(
            __('Adversarial Code Generator', 'adversarial-code-generator'),
            __('Adversarial Code Generator', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator',
            [$this, 'render_admin_page'],
            'dashicons-editor-code',
            6
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Settings', 'adversarial-code-generator'),
            __('Settings', 'adversarial-code-generator'),
            'manage_code_generator_settings',
            'adversarial-code-generator-settings',
            [$this, 'render_settings_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Analytics', 'adversarial-code-generator'),
            __('Analytics', 'adversarial-code-generator'),
            'view_code_analytics',
            'adversarial-code-generator-analytics',
            [$this, 'render_analytics_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Execute Code', 'adversarial-code-generator'),
            __('Execute Code', 'adversarial-code-generator'),
            'execute_generated_code',
            'adversarial-code-generator-execute',
            [$this, 'render_execution_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Git Repositories', 'adversarial-code-generator'),
            __('Git Repositories', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-git',
            [$this, 'render_git_management_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Documentation', 'adversarial-code-generator'),
            __('Documentation', 'adversarial-code-generator'),
            'read',
            'adversarial-code-generator-docs',
            [$this, 'render_docs_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Code Templates', 'adversarial-code-generator'),
            __('Code Templates', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-templates',
            [$this, 'render_templates_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Collaboration Projects', 'adversarial-code-generator'),
            __('Collaboration Projects', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-collaboration',
            [$this, 'render_collaboration_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Code History', 'adversarial-code-generator'),
            __('Code History', 'adversarial-code-generator'),
            'view_code_history',
            'adversarial-code-generator-history',
            [$this, 'render_history_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Security Management', 'adversarial-code-generator'),
            __('Security Management', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-security',
            [$this, 'render_security_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Performance Optimization', 'adversarial-code-generator'),
            __('Performance Optimization', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-performance',
            [$this, 'render_performance_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Code Snippets', 'adversarial-code-generator'),
            __('Code Snippets', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-snippets',
            [$this, 'render_snippets_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Code Environments', 'adversarial-code-generator'),
            __('Code Environments', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-environments',
            [$this, 'render_environments_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('CI/CD Pipelines', 'adversarial-code-generator'),
            __('CI/CD Pipelines', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-ci',
            [$this, 'render_ci_pipelines_page']
        );
    }

    public function render_ci_pipelines_page() {
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.', 'adversarial-code-generator'));
        }
        ?>
        <div class="wrap">
            <h1><?php esc_html_e('CI/CD Pipelines', 'adversarial-code-generator'); ?></h1>
            <div class="adversarial-ci-pipelines-container">
                <div class="pipeline-actions">
                    <h2><?php esc_html_e('Create New Pipeline', 'adversarial-code-generator'); ?></h2>
                    <form method="post" class="pipeline-form">
                        <?php wp_nonce_field('adversarial_create_pipeline', 'adversarial_nonce'); ?>
                        <div class="form-group">
                            <label for="pipeline_name"><?php esc_html_e('Pipeline Name:', 'adversarial-code-generator'); ?></label>
                            <input type="text" id="pipeline_name" name="pipeline_name" class="regular-text" required>
                        </div>
                        <div class="form-group">
                            <label for="pipeline_repository"><?php esc_html_e('Repository URL:', 'adversarial-code-generator'); ?></label>
                            <input type="url" id="pipeline_repository" name="pipeline_repository" class="regular-text" required>
                        </div>
                        <div class="form-group">
                            <label for="pipeline_branch"><?php esc_html_e('Branch:', 'adversarial-code-generator'); ?></label>
                            <input type="text" id="pipeline_branch" name="pipeline_branch" class="regular-text" value="main">
                        </div>
                        <div class="form-group">
                            <label for="pipeline_build_command"><?php esc_html_e('Build Command:', 'adversarial-code-generator'); ?></label>
                            <input type="text" id="pipeline_build_command" name="pipeline_build_command" class="regular-text">
                        </div>
                        <div class="form-group">
                            <label for="pipeline_test_command"><?php esc_html_e('Test Command:', 'adversarial-code-generator'); ?></label>
                            <input type="text" id="pipeline_test_command" name="pipeline_test_command" class="regular-text">
                        </div>
                        <button type="submit" class="button button-primary"><?php esc_html_e('Create Pipeline', 'adversarial-code-generator'); ?></button>
                    </form>
                    
                    <?php
                    if (isset($_POST['pipeline_name']) && wp_verify_nonce($_POST['adversarial_nonce'], 'adversarial_create_pipeline')) {
                        try {
                            $name = sanitize_text_field($_POST['pipeline_name']);
                            $repository = esc_url_raw($_POST['pipeline_repository']);
                            $branch = isset($_POST['pipeline_branch']) ? sanitize_text_field($_POST['pipeline_branch']) : 'main';
                            $build_command = isset($_POST['pipeline_build_command']) ? sanitize_text_field($_POST['pipeline_build_command']) : '';
                            $test_command = isset($_POST['pipeline_test_command']) ? sanitize_text_field($_POST['pipeline_test_command']) : '';
                            
                            $ci = new CIIntegration();
                            $ci->create_pipeline($name, [
                                'repository' => $repository,
                                'branch' => $branch,
                                'build_command' => $build_command,
                                'test_command' => $test_command
                            ]);
                            
                            echo '<div class="notice notice-success"><p>' . esc_html__('Pipeline created successfully!', 'adversarial-code-generator') . '</p></div>';
                        } catch (Exception $e) {
                            echo '<div class="notice notice-error"><p>' . esc_html__('Pipeline creation failed: ', 'adversarial-code-generator') . esc_html($e->getMessage()) . '</p></div>';
                        }
                    }
                    ?>
                </div>
                
                <div class="pipelines-list">
                    <h2><?php esc_html_e('Existing Pipelines', 'adversarial-code-generator'); ?></h2>
                    <table class="wp-list-table widefat fixed striped">
                        <thead>
                            <tr>
                                <th><?php esc_html_e('Pipeline ID', 'adversarial-code-generator'); ?></th>
                                <th><?php esc_html_e('Name', 'adversarial-code-generator'); ?></th>
                                <th><?php esc_html_e('Repository', 'adversarial-code-generator'); ?></th>
                                <th><?php esc_html_e('Branch', 'adversarial-code-generator'); ?></th>
                                <th><?php esc_html_e('Last Run', 'adversarial-code-generator'); ?></th>
                                <th><?php esc_html_e('Actions', 'adversarial-code-generator'); ?></th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $ci = new CIIntegration();
                            $pipelines = $ci->list_pipelines();
                            
                            foreach ($pipelines as $pipeline) {
                                ?>
                                <tr>
                                    <td><?php echo esc_html($pipeline['id']); ?></td>
                                    <td><?php echo esc_html($pipeline['name']); ?></td>
                                    <td><?php echo esc_html($pipeline['repository']); ?></td>
                                    <td><?php echo esc_html($pipeline['branch']); ?></td>
                                    <td><?php echo esc_html($pipeline['last_run'] ?: 'Never'); ?></td>
                                    <td>
                                        <button class="button run-pipeline" data-id="<?php echo esc_attr($pipeline['id']); ?>">
                                            <?php esc_html_e('Run Pipeline', 'adversarial-code-generator'); ?>
                                        </button>
                                        <button class="button edit-pipeline" data-id="<?php echo esc_attr($pipeline['id']); ?>">
                                            <?php esc_html_e('Edit', 'adversarial-code-generator'); ?>
                                        </button>
                                        <button class="button delete-pipeline" data-id="<?php echo esc_attr($pipeline['id']); ?>">
                                            <?php esc_html_e('Delete', 'adversarial-code-generator'); ?>
                                        </button>
                                    </td>
                                </tr>
                                <?php
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <?php
    }
}