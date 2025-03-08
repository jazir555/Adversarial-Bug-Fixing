class CodeDiffViewer {
    public function __construct() {
        add_shortcode('adversarial_code_diff', [$this, 'code_diff_shortcode']);
    }

    public function generate_diff($code1, $code2) {
        // Simple implementation using string comparison
        $diff = [];
        $code1_lines = explode("\n", $code1);
        $code2_lines = explode("\n", $code2);
        
        foreach ($code1_lines as $index => $line) {
            if (!isset($code2_lines[$index]) || $line != $code2_lines[$index]) {
                $diff[] = [
                    'type' => 'deleted',
                    'content' => $line
                ];
            }
        }
        
        foreach ($code2_lines as $index => $line) {
            if (!isset($code1_lines[$index]) || $line != $code1_lines[$index]) {
                $diff[] = [
                    'type' => 'added',
                    'content' => $line
                ];
            }
        }
        
        return $diff;
    }

    public function code_diff_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-diff">
            <h2><?php esc_html_e('Code Comparison', 'adversarial-code-generator'); ?></h2>
            <div class="diff-container">
                <div class="diff-pane">
                    <h3><?php esc_html_e('Original Code', 'adversarial-code-generator'); ?></h3>
                    <div class="code-editor-wrapper original-code" data-language="python" data-theme="monokai" style="height: 300px;"></div>
                    <input type="hidden" class="original-code-value" name="original_code_value" value="">
                </div>
                <div class="diff-pane">
                    <h3><?php esc_html_e('Modified Code', 'adversarial-code-generator'); ?></h3>
                    <div class="code-editor-wrapper modified-code" data-language="python" data-theme="monokai" style="height: 300px;"></div>
                    <input type="hidden" class="modified-code-value" name="modified_code_value" value="">
                </div>
            </div>
            <button class="button button-primary generate-diff"><?php esc_html_e('Generate Diff', 'adversarial-code-generator'); ?></button>
            <div class="diff-results"></div>
        </div>
        <?php
        return ob_get_clean();
    }
}