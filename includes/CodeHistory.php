class CodeHistory {
    private $history_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->history_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/history';
        wp_mkdir_p($this->history_dir);
        
        add_shortcode('adversarial_code_history', [$this, 'history_shortcode']);
    }

    public function save_history($code, $language, $prompt, $user_id) {
        $history_entry = [
            'code' => $code,
            'language' => $language,
            'prompt' => $prompt,
            'user_id' => $user_id,
            'date' => current_time('mysql')
        ];
        
        $filename = $this->history_dir . '/' . uniqid('code_') . '.json';
        file_put_contents($filename, wp_json_encode($history_entry));
    }

    public function get_history($limit = 20) {
        $history_files = glob($this->history_dir . '/*.json');
        usort($history_files, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        $history = [];
        foreach (array_slice($history_files, 0, $limit) as $file) {
            $content = file_get_contents($file);
            $history[] = json_decode($content, true);
        }
        
        return $history;
    }

    public function history_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-history">
            <h2><?php esc_html_e('Code History', 'adversarial-code-generator'); ?></h2>
            <div class="history-filters">
                <input type="text" id="history-search" placeholder="<?php esc_attr_e('Search history...', 'adversarial-code-generator'); ?>">
                <select id="history-language-filter">
                    <option value="all"><?php esc_html_e('All Languages', 'adversarial-code-generator'); ?></option>
                    <option value="python">Python</option>
                    <option value="javascript">JavaScript</option>
                    <option value="java">Java</option>
                    <option value="php">PHP</option>
                    <option value="cpp">C++</option>
                    <option value="csharp">C#</option>
                    <option value="go">Go</option>
                    <option value="ruby">Ruby</option>
                </select>
            </div>
            <div class="history-list">
                <?php
                $history = $this->get_history();
                foreach ($history as $entry) {
                    ?>
                    <div class="history-item">
                        <div class="history-header">
                            <span class="history-language"><?php printf(__('Language: %s', 'adversarial-code-generator'), esc_html($entry['language'])); ?></span>
                            <span class="history-date"><?php echo esc_html($entry['date']); ?></span>
                        </div>
                        <div class="history-prompt">
                            <strong><?php esc_html_e('Prompt:', 'adversarial-code-generator'); ?></strong>
                            <p><?php echo esc_html($entry['prompt']); ?></p>
                        </div>
                        <div class="history-code">
                            <strong><?php esc_html_e('Code:', 'adversarial-code-generator'); ?></strong>
                            <div class="code-preview"><?php echo esc_html(substr($entry['code'], 0, 200)) . '...'; ?></div>
                        </div>
                        <div class="history-actions">
                            <button class="button view-code" data-code="<?php echo esc_attr($entry['code']); ?>">
                                <?php esc_html_e('View Full Code', 'adversarial-code-generator'); ?>
                            </button>
                            <button class="button reuse-code" data-code="<?php echo esc_attr($entry['code']); ?>">
                                <?php esc_html_e('Reuse Code', 'adversarial-code-generator'); ?>
                            </button>
                        </div>
                    </div>
                    <?php
                }
                ?>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
}