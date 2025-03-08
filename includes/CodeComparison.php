class CodeComparison {
    public function __construct() {
        add_shortcode('adversarial_code_comparison', [$this, 'render_comparison_shortcode']);
    }
    
    public function render_comparison_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-comparison">
            <div class="comparison-container">
                <div class="comparison-pane">
                    <h3><?php esc_html_e('Original Code', 'adversarial-code-generator'); ?></h3>
                    <div class="code-editor-wrapper original-code" data-language="python" data-theme="monokai"