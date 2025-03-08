class CodeExport {
    public function __construct() {
        add_action('admin_post_export_code', [$this, 'handle_export']);
        add_action('wp_ajax_export_code', [$this, 'handle_export']);
        add_shortcode('adversarial_code_export', [$this, 'export_shortcode']);
    }

    public function handle_export() {
        check_admin_referer('export_code');
        
        $code = isset($_POST['code']) ? sanitize_textarea_field($_POST['code']) : '';
        $filename = isset($_POST['filename']) ? sanitize_file_name($_POST['filename']) : 'code_export_' . date('YmdHis');
        $language = isset($_POST['language']) ? sanitize_text_field($_POST['language']) : 'python';
        
        $this->export_code($code, $filename . '.' . $this->get_file_extension($language));
        exit;
    }

    public function export_code($code, $filename) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename=' . $filename);
        header('Expires: 0');
        header('Cache-Control: must-revalidate');
        header('Pragma: public');
        echo $code;
    }

    public function export_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-export">
            <h3><?php esc_html_e('Export Code', 'adversarial-code-generator'); ?></h3>
            <form method="post" class="export-form">
                <?php wp_nonce_field('export_code'); ?>
                <div class="form-group">
                    <label for="code_to_export"><?php esc_html_e('Code to Export:', 'adversarial-code-generator'); ?></label>
                    <textarea id="code_to_export" name="code" class="large-text code" rows="10" required></textarea>
                </div>
                <div class="form-group">
                    <label for="export_filename"><?php esc_html_e('Filename:', 'adversarial-code-generator'); ?></label>
                    <input type="text" id="export_filename" name="filename" class="regular-text" value="code_export" required>
                </div>
                <div class="form-group">
                    <label for="export_language"><?php esc_html_e('Language:', 'adversarial-code-generator'); ?></label>
                    <select id="export_language" name="language" class="regular-text">
                        <option value="python" selected>Python</option>
                        <option value="javascript">JavaScript</option>
                        <option value="java">Java</option>
                        <option value="php">PHP</option>
                        <option value="cpp">C++</option>
                        <option value="csharp">C#</option>
                        <option value="go">Go</option>
                        <option value="ruby">Ruby</option>
                    </select>
                </div>
                <button type="submit" class="button button-primary"><?php esc_html_e('Export Code', 'adversarial-code-generator'); ?></button>
            </form>
        </div>
        <?php
        return ob_get_clean();
    }

    private function get_file_extension($language) {
        switch ($language) {
            case 'python': return 'py';
            case 'javascript': return 'js';
            case 'java': return 'java';
            case 'php': return 'php';
            case 'cpp': return 'cpp';
            case 'csharp': return 'cs';
            case 'go': return 'go';
            case 'ruby': return 'rb';
            default: return 'txt';
        }
    }
}