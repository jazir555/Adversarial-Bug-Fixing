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
            'manage_options',
            'adversarial-code-generator-settings',
            [$this, 'render_settings_page']
        );
        
        add_submenu_page(
            'adversarial-code-generator',
            __('Analytics', 'adversarial-code-generator'),
            __('Analytics', 'adversarial-code-generator'),
            'manage_options',
            'adversarial-code-generator-analytics',
            [$this, 'render_analytics_page']
        );
    }

    public function render_admin_page() {
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.', 'adversarial-code-generator'));
        }
        ?>
        <div class="wrap">
            <h1><?php esc_html_e('Adversarial Code Generator', 'adversarial-code-generator'); ?></h1>
            <div id="adversarial-generator-admin">
                <form method="post" class="adversarial-generator-form">
                    <?php wp_nonce_field('adversarial_generate_code', 'adversarial_nonce'); ?>
                    <div class="form-group">
                        <label for="code_prompt"><?php esc_html_e('Code Request:', 'adversarial-code-generator'); ?></label>
                        <textarea id="code_prompt" name="code_prompt" rows="10" class="large-text code" placeholder="<?php esc_attr_e('Enter your code generation request...', 'adversarial-code-generator'); ?>"></textarea>
                    </div>
                    <div class="form-group">
                        <label for="features"><?php esc_html_e('Additional Features (optional):', 'adversarial-code-generator'); ?></label>
                        <textarea id="features" name="features" rows="5" class="large-text code" placeholder="<?php esc_attr_e('Enter additional features to implement after initial code generation...', 'adversarial-code-generator'); ?>"></textarea>
                    </div>
                    <div class="form-group">
                        <label for="language"><?php esc_html_e('Programming Language:', 'adversarial-code-generator'); ?></label>
                        <select id="language" name="language" class="regular-text">
                            <option value="python" selected>Python</option>
                            <option value="javascript">JavaScript</option>
                            <option value="typescript">TypeScript</option>
                            <option value="java">Java</option>
                            <option value="cpp">C++</option>
                            <option value="csharp">C#</option>
                            <option value="go">Go</option>
                            <option value="ruby">Ruby</option>
                            <option value="php">PHP</option>
                        </select>
                    </div>
                    <button type="submit" class="button button-primary"><?php esc_html_e('Generate Code', 'adversarial-code-generator'); ?></button>
                    <div class="loading-indicator" style="display: none;">
                        <p><?php esc_html_e('Generating code... Please wait.', 'adversarial-code-generator'); ?></p>
                    </div>
                </form>
                
                <?php
                if (isset($_POST['code_prompt']) && wp_verify_nonce($_POST['adversarial_nonce'], 'adversarial_generate_code')) {
                    try {
                        $prompt = sanitize_text_field($_POST['code_prompt']);
                        $features = isset($_POST['features']) ? explode("\n", sanitize_text_field($_POST['features'])) : [];
                        $language = isset($_POST['language']) ? sanitize_text_field($_POST['language']) : 'python';
                        
                        $workflow = AdversarialCore::get_instance()->workflow_manager;
                        
                        if (!empty($features)) {
                            $result = $workflow->generate_feature_enhanced_code($prompt, $features, $language);
                        } else {
                            $result = $workflow->run_workflow($prompt, $language);
                        }
                        
                        echo '<div class="notice notice-success"><p>' . esc_html__('Code generation successful!', 'adversarial-code-generator') . '</p></div>';
                        echo '<div class="generated-code"><pre>' . esc_html($result['code']) . '</pre></div>';
                        echo '<div class="generation-stats">';
                        echo '<p>' . esc_html__('Iterations: ', 'adversarial-code-generator') . $result['iterations'] . '</p>';
                        echo '<p>' . esc_html__('Duration: ', 'adversarial-code-generator') . number_format($result['duration'], 2) . 's</p>';
                        if (!empty($features)) {
                            echo '<p>' . esc_html__('Features implemented: ', 'adversarial-code-generator') . $result['features_implemented'] . '/' . count($features) . '</p>';
                        }
                        echo '</div>';
                    } catch (Exception $e) {
                        echo '<div class="notice notice-error"><p>' . esc_html__('Error generating code: ', 'adversarial-code-generator') . esc_html($e->getMessage()) . '</p></div>';
                    }
                }
                ?>
                
                <h2><?php esc_html_e('Previous Requests', 'adversarial-code-generator'); ?></h2>
                <table class="wp-list-table widefat fixed striped">
                    <thead>
                        <tr>
                            <th><?php esc_html_e('ID', 'adversarial-code-generator'); ?></th>
                            <th><?php esc_html_e('Prompt', 'adversarial-code-generator'); ?></th>
                            <th><?php esc_html_e('Language', 'adversarial-code-generator'); ?></th>
                            <th><?php esc_html_e('Status', 'adversarial-code-generator'); ?></th>
                            <th><?php esc_html_e('Created At', 'adversarial-code-generator'); ?></th>
                            <th><?php esc_html_e('Actions', 'adversarial-code-generator'); ?></th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                        $database = Database::get_instance();
                        $entries = $database->get_entries();
                        
                        foreach ($entries as $entry) {
                            ?>
                            <tr>
                                <td><?php echo esc_html($entry->id); ?></td>
                                <td><?php echo esc_html(substr($entry->prompt, 0, 50)); ?></td>
                                <td><?php echo esc_html($entry->language); ?></td>
                                <td><?php echo esc_html($entry->status); ?></td>
                                <td><?php echo esc_html($entry->created_at); ?></td>
                                <td>
                                    <a href="<?php echo wp_nonce_url(admin_url('admin.php?page=adversarial-code-generator&view=entry&id=' . $entry->id), 'adversarial_view_entry'); ?>"><?php esc_html_e('View', 'adversarial-code-generator'); ?></a>
                                </td>
                            </tr>
                            <?php
                        }
                        ?>
                    </tbody>
                </table>
            </div>
        </div>
        <?php
    }

    public function render_settings_page() {
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.', 'adversarial-code-generator'));
        }
        ?>
        <div class="wrap">
            <h1><?php esc_html_e('Adversarial Code Generator Settings', 'adversarial-code-generator'); ?></h1>
            <form action="options.php" method="post">
                <?php
                settings_fields('adversarial_settings');
                do_settings_sections('adversarial-code-generator-settings');
                submit_button();
                ?>
            </form>
        </div>
        <?php
    }

    public function render_analytics_page() {
        if (!current_user_can('manage_options')) {
            wp_die(__('You do not have sufficient permissions to access this page.', 'adversarial-code-generator'));
        }
        
        $analytics = new Analytics();
        $usage_report = $analytics->get_usage_report(30);
        ?>
        <div class="wrap">
            <h1><?php esc_html_e('Adversarial Code Generator Analytics', 'adversarial-code-generator'); ?></h1>
            
            <h2><?php esc_html_e('API Usage (Last 30 Days)', 'adversarial-code-generator'); ?></h2>
            <table class="wp-list-table widefat fixed striped">
                <thead>
                    <tr>
                        <th><?php esc_html_e('Model', 'adversarial-code-generator'); ?></th>
                        <th><?php esc_html_e('Action', 'adversarial-code-generator'); ?></th>
                        <th><?php esc_html_e('Calls', 'adversarial-code-generator'); ?></th>
                        <th><?php esc_html_e('Tokens In', 'adversarial-code-generator'); ?></th>
                        <th><?php esc_html_e('Tokens Out', 'adversarial-code-generator'); ?></th>
                        <th><?php esc_html_e('Avg Duration (s)', 'adversarial-code-generator'); ?></th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($usage_report as $row): ?>
                    <tr>
                        <td><?php echo esc_html($row->model_id); ?></td>
                        <td><?php echo esc_html($row->action); ?></td>
                        <td><?php echo esc_html($row->calls); ?></td>
                        <td><?php echo esc_html(number_format($row->tokens_in)); ?></td>
                        <td><?php echo esc_html(number_format($row->tokens_out)); ?></td>
                        <td><?php echo esc_html(number_format($row->avg_duration, 2)); ?></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
            
            <h2><?php esc_html_e('Completion Rates', 'adversarial-code-generator'); ?></h2>
            <?php
            // Add more analytics sections as needed
            ?>
        </div>
        <?php
    }
}