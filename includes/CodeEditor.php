class CodeEditor {
    public function __construct() {
        add_action('wp_enqueue_scripts', [$this, 'enqueue_assets']);
        add_action('admin_enqueue_scripts', [$this, 'enqueue_assets']);
    }
    
    public function enqueue_assets() {
        wp_enqueue_style('adversarial-ace-editor', plugins_url('assets/css/ace-editor.css', __FILE__));
        wp_enqueue_script('adversarial-ace-editor', plugins_url('assets/js/ace/ace.js', __FILE__), [], ADVERSARIAL_VERSION, true);
        wp_enqueue_script('adversarial-ace-mode-python', plugins_url('assets/js/ace/mode-python.js', __FILE__), ['adversarial-ace-editor'], ADVERSARIAL_VERSION, true);
        wp_enqueue_script('adversarial-ace-mode-javascript', plugins_url('assets/js/ace/mode-javascript.js', __FILE__), ['adversarial-ace-editor'], ADVERSARIAL_VERSION, true);
        wp_enqueue_script('adversarial-ace-mode-java', plugins_url('assets/js/ace/mode-java.js', __FILE__), ['adversarial-ace-editor'], ADVERSARIAL_VERSION, true);
        wp_enqueue_script('adversarial-ace-mode-php', plugins_url('assets/js/ace/mode-php.js', __FILE__), ['adversarial-ace-editor'], ADVERSARIAL_VERSION, true);
        wp_enqueue_script('adversarial-ace-theme-monokai', plugins_url('assets/js/ace/theme-monokai.js', __FILE__), ['adversarial-ace-editor'], ADVERSARIAL_VERSION, true);
        wp_enqueue_script('adversarial-code-editor', plugins_url('assets/js/code-editor.js', __FILE__), ['adversarial-ace-editor'], ADVERSARIAL_VERSION, true);
        
        // Pass settings to JavaScript
        $settings = [
            'defaultLanguage' => 'python',
            'theme' => get_user_meta(get_current_user_id(), 'adversarial_editor_theme', true) ?: 'monokai'
        ];
        wp_localize_script('adversarial-code-editor', 'adversarialEditorSettings', $settings);
    }
    
    public function render_editor($id, $language = 'python', $theme = 'monokai', $height = '400px', $initial_code = '') {
        ob_start(); ?>
        <div class="adversarial-code-editor-wrapper" id="<?php echo esc_attr($id); ?>">
            <div class="code-editor-container" data-language="<?php echo esc_attr($language); ?>" data-theme="<?php echo esc_attr($theme); ?>" style="height: <?php echo esc_attr($height); ?>">
                <?php echo esc_html($initial_code); ?>
            </div>
            <input type="hidden" class="code-editor-value" name="<?php echo esc_attr($id); ?>" value="<?php echo esc_attr($initial_code); ?>">
        </div>
        <?php
        return ob_get_clean();
    }
}