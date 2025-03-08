class Collaboration {
    public function __construct() {
        add_action('wp_enqueue_scripts', [$this, 'enqueue_scripts']);
        add_shortcode('adversarial_collaboration', [$this, 'collaboration_shortcode']);
    }

    public function enqueue_scripts() {
        wp_enqueue_script('adversarial-collaboration', plugins_url('assets/js/collaboration.js', __FILE__), ['jquery'], ADVERSARIAL_VERSION, true);
        wp_enqueue_style('adversarial-collaboration-css', plugins_url('assets/css/collaboration.css', __FILE__), [], ADVERSARIAL_VERSION);
    }

    public function collaboration_shortcode($atts) {
        $atts = shortcode_atts([
            'project_id' => uniqid('collab_'),
        ], $atts);
        
        ob_start(); ?>
        <div class="adversarial-collaboration" data-project-id="<?php echo esc_attr($atts['project_id']); ?>">
            <h2><?php esc_html_e('Collaborative Code Development', 'adversarial-code-generator'); ?></h2>
            <div class="collaboration-editor">
                <div class="code-editor-wrapper collaboration-code" data-language="python" data-theme="monokai" style="height: 300px;"></div>
                <input type="hidden" class="collaboration-code-value" name="collaboration_code_value" value="">
            </div>
            <div class="collaboration-users">
                <h3><?php esc_html_e('Active Collaborators', 'adversarial-code-generator'); ?></h3>
                <ul class="collaborators-list"></ul>
            </div>
            <div class="collaboration-chat">
                <h3><?php esc_html_e('Team Chat', 'adversarial-code-generator'); ?></h3>
                <div class="chat-messages"></div>
                <div class="chat-input">
                    <input type="text" placeholder="<?php esc_attr_e('Type a message...', 'adversarial-code-generator'); ?>" class="chat-message-input">
                    <button class="button send-message"><?php esc_html_e('Send', 'adversarial-code-generator'); ?></button>
                </div>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
}