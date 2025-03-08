class CodeImport {
    public function __construct() {
        add_action('admin_post_import_code', [$this, 'handle_import']);
        add_action('wp_ajax_import_code', [$this, 'handle_import']);
        add_shortcode('adversarial_code_import', [$this, 'import_shortcode']);
    }

    public function handle_import() {
        check_admin_referer('import_code');
        
        if (!isset($_FILES['code_file'])) {
            wp_send_json_error(['message' => __('No file uploaded', 'adversarial-code-generator')]);
        }
        
        $file = $_FILES['code_file'];
        
        if ($file['error'] !== UPLOAD_ERR_OK) {
            wp_send_json_error(['message' => __('File upload error', 'adversarial-code-generator')]);
        }
        
        $code = file_get_contents($file['tmp_name']);
        $language = $this->detect_language($file['name']);
        
        wp_send_json_success([
            'code' => $code,
            'language' => $language,
            'filename' => $file['name']
        ]);
    }

    public function import_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-import">
            <h3><?php esc_html_e('Import Code', 'adversarial-code-generator'); ?></h3>
            <form method="post" enctype="multipart/form-data" class="import-form">
                <?php wp_nonce_field('import_code'); ?>
                <div class="form-group">
                    <label for="code_file"><?php esc_html_e('Upload Code File:', 'adversarial-code-generator'); ?></label>
                    <input type="file" id="code_file" name="code_file" accept=".py,.js,.java,.php,.cpp,.cs,.go,.rb" required>
                </div>
                <button type="submit" class="button button-primary"><?php esc_html_e('Import Code', 'adversarial-code-generator'); ?></button>
            </form>
        </div>
        <?php
        return ob_get_clean();
    }

    private function detect_language($filename) {
        $extension = pathinfo($filename, PATHINFO_EXTENSION);
        
        switch ($extension) {
            case 'py': return 'python';
            case 'js': return 'javascript';
            case 'java': return 'java';
            case 'php': return 'php';
            case 'cpp': return 'cpp';
            case 'cs': return 'csharp';
            case 'go': return 'go';
            case 'rb': return 'ruby';
            default: return 'python';
        }
    }
}