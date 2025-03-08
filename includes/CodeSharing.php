class CodeSharing {
    private $shares_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->shares_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/shares';
        wp_mkdir_p($this->shares_dir);
        
        add_shortcode('adversarial_code_sharing', [$this, 'code_sharing_shortcode']);
    }

    public function share_code($code_id, $email) {
        // Implement sharing logic
        // This is a simplified version - in a real implementation, you would:
        // 1. Generate a unique share ID
        // 2. Store the share information
        // 3. Send an email with a share link
        // 4. Return the share ID
        
        $share_id = uniqid('share_');
        $share_data = [
            'code_id' => $code_id,
            'email' => $email,
            'date' => current_time('mysql')
        ];
        
        file_put_contents($this->shares_dir . "/{$share_id}.json", wp_json_encode($share_data));
        
        return $share_id;
    }

    public function get_shared_code($share_id) {
        $file = $this->shares_dir . "/{$share_id}.json";
        if (!file_exists($file)) {
            return null;
        }
        
        return json_decode(file_get_contents($file), true);
    }

    public function code_sharing_shortcode($atts) {
        $atts = shortcode_atts([
            'code_id' => 0
        ], $atts);
        
        if (!$atts['code_id']) {
            return '<p>' . esc_html__('Invalid code ID', 'adversarial-code-generator') . '</p>';
        }
        
        ob_start(); ?>
        <div class="adversarial-code-sharing">
            <h3><?php esc_html_e('Share Code', 'adversarial-code-generator'); ?></h3>
            <form method="post" class="share-form">
                <?php wp_nonce_field('adversarial_share_code', 'adversarial_nonce'); ?>
                <input type="hidden" name="code_id" value="<?php echo esc_attr($atts['code_id']); ?>">
                <div class="form-group">
                    <label for="share_email"><?php esc_html_e('Recipient Email:', 'adversarial-code-generator'); ?></label>
                    <input type="email" id="share_email" name="share_email" class="regular-text" required>
                </div>
                <button type="submit" class="button button-primary"><?php esc_html_e('Share Code', 'adversarial-code-generator'); ?></button>
            </form>
            
            <?php
            if (isset($_POST['share_email']) && wp_verify_nonce($_POST['adversarial_nonce'], 'adversarial_share_code')) {
                try {
                    $code_id = sanitize_text_field($_POST['code_id']);
                    $email = sanitize_email($_POST['share_email']);
                    
                    $share_id = $this->share_code($code_id, $email);
                    
                    echo '<div class="notice notice-success"><p>' . esc_html__('Code shared successfully!', 'adversarial-code-generator') . '</p></div>';
                    echo '<p>' . esc_html__('Share ID: ', 'adversarial-code-generator') . esc_html($share_id) . '</p>';
                } catch (Exception $e) {
                    echo '<div class="notice notice-error"><p>' . esc_html__('Sharing failed: ', 'adversarial-code-generator') . esc_html($e->getMessage()) . '</p></div>';
                }
            }
            ?>
        </div>
        <?php
        return ob_get_clean();
    }
}