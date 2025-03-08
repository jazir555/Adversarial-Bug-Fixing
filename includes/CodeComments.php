class CodeComments {
    private $comments_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->comments_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/comments';
        wp_mkdir_p($this->comments_dir);
        
        add_shortcode('adversarial_code_comments', [$this, 'code_comments_shortcode']);
    }

    public function add_comment($code_id, $comment, $user_id) {
        $comment_data = [
            'user_id' => $user_id,
            'comment' => $comment,
            'date' => current_time('mysql')
        ];
        
        $filename = $this->comments_dir . "/code_{$code_id}_comments.json";
        $existing_comments = file_exists($filename) ? json_decode(file_get_contents($filename), true) : [];
        $existing_comments[] = $comment_data;
        
        file_put_contents($filename, wp_json_encode($existing_comments));
    }

    public function get_comments($code_id) {
        $filename = $this->comments_dir . "/code_{$code_id}_comments.json";
        if (!file_exists($filename)) {
            return [];
        }
        
        return json_decode(file_get_contents($filename), true);
    }

    public function code_comments_shortcode($atts) {
        $atts = shortcode_atts([
            'code_id' => 0
        ], $atts);
        
        if (!$atts['code_id']) {
            return '<p>' . esc_html__('Invalid code ID', 'adversarial-code-generator') . '</p>';
        }
        
        ob_start(); ?>
        <div class="adversarial-code-comments">
            <h3><?php esc_html_e('Comments', 'adversarial-code-generator'); ?></h3>
            <?php if (is_user_logged_in()): ?>
                <form method="post" class="add-comment-form">
                    <?php wp_nonce_field('adversarial_add_comment', 'adversarial_nonce'); ?>
                    <input type="hidden" name="code_id" value="<?php echo esc_attr($atts['code_id']); ?>">
                    <div class="form-group">
                        <label for="comment"><?php esc_html_e('Add Comment:', 'adversarial-code-generator'); ?></label>
                        <textarea id="comment" name="comment" class="large-text code" rows="3" required></textarea>
                    </div>
                    <button type="submit" class="button button-primary"><?php esc_html_e('Add Comment', 'adversarial-code-generator'); ?></button>
                </form>
            <?php endif; ?>
            
            <div class="comments-list">
                <?php
                $comments = $this->get_comments($atts['code_id']);
                if (empty($comments)) {
                    echo '<p>' . esc_html__('No comments yet', 'adversarial-code-generator') . '</p>';
                } else {
                    foreach ($comments as $comment) {
                        $user = get_userdata($comment['user_id']);
                        ?>
                        <div class="comment-item">
                            <div class="comment-header">
                                <strong><?php echo esc_html($user ? $user->display_name : __('Anonymous', 'adversarial-code-generator')); ?></strong>
                                <span class="comment-date"><?php echo esc_html($comment['date']); ?></span>
                            </div>
                            <div class="comment-content">
                                <?php echo wpautop(esc_html($comment['comment'])); ?>
                            </div>
                        </div>
                        <?php
                    }
                }
                ?>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
}