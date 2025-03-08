class CodeSnippets {
    private $snippets_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->snippets_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/snippets';
        wp_mkdir_p($this->snippets_dir);
        
        add_shortcode('adversarial_code_snippets', [$this, 'code_snippets_shortcode']);
    }

    public function save_snippet($title, $code, $language, $tags = []) {
        $snippet = [
            'title' => $title,
            'code' => $code,
            'language' => $language,
            'tags' => $tags,
            'date' => current_time('mysql'),
            'user_id' => get_current_user_id()
        ];
        
        $filename = $this->snippets_dir . '/' . uniqid('snippet_') . '.json';
        file_put_contents($filename, wp_json_encode($snippet));
        
        return basename($filename);
    }

    public function get_snippets($tags = [], $limit = 20) {
        $snippets = [];
        $snippet_files = glob($this->snippets_dir . '/*.json');
        
        usort($snippet_files, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        foreach (array_slice($snippet_files, 0, $limit) as $file) {
            $content = json_decode(file_get_contents($file), true);
            if (empty($tags) || count(array_intersect($content['tags'], $tags)) > 0) {
                $snippets[] = $content + ['id' => basename($file)];
            }
        }
        
        return $snippets;
    }

    public function get_snippet($snippet_id) {
        $file = $this->snippets_dir . '/' . $snippet_id;
        if (!file_exists($file)) {
            return null;
        }
        
        return json_decode(file_get_contents($file), true);
    }

    public function code_snippets_shortcode($atts) {
        ob_start(); ?>
        <div class="adversarial-code-snippets">
            <h2><?php esc_html_e('Code Snippets Library', 'adversarial-code-generator'); ?></h2>
            
            <div class="snippet-actions">
                <button class="button button-primary add-snippet"><?php esc_html_e('Add New Snippet', 'adversarial-code-generator'); ?></button>
            </div>
            
            <div class="snippets-list">
                <?php
                $snippets = $this->get_snippets();
                if (empty($snippets)) {
                    echo '<p>' . esc_html__('No snippets found', 'adversarial-code-generator') . '</p>';
                } else {
                    foreach ($snippets as $snippet) {
                        ?>
                        <div class="snippet-item">
                            <h3><?php echo esc_html($snippet['title']); ?></h3>
                            <div class="snippet-meta">
                                <span class="snippet-language"><?php printf(__('Language: %s', 'adversarial-code-generator'), esc_html($snippet['language'])); ?></span>
                                <span class="snippet-date"><?php echo esc_html($snippet['date']); ?></span>
                            </div>
                            <div class="snippet-code">
                                <pre><code class="language-<?php echo esc_attr($snippet['language']); ?>"><?php echo esc_html($snippet['code']); ?></code></pre>
                            </div>
                            <div class="snippet-tags">
                                <?php foreach ($snippet['tags'] as $tag): ?>
                                    <span class="tag"><?php echo esc_html($tag); ?></span>
                                <?php endforeach; ?>
                            </div>
                            <div class="snippet-actions">
                                <button class="button copy-snippet" data-id="<?php echo esc_attr($snippet['id']); ?>">
                                    <?php esc_html_e('Copy Snippet', 'adversarial-code-generator'); ?>
                                </button>
                                <button class="button insert-snippet" data-id="<?php echo esc_attr($snippet['id']); ?>">
                                    <?php esc_html_e('Insert into Editor', 'adversarial-code-generator'); ?>
                                </button>
                            </div>
                        </div>
                        <?php
                    }
                }
                ?>
            </div>
            
            <div class="add-snippet-modal" style="display: none;">
                <h3><?php esc_html_e('Add New Code Snippet', 'adversarial-code-generator'); ?></h3>
                <form method="post" class="add-snippet-form">
                    <?php wp_nonce_field('adversarial_add_snippet', 'adversarial_nonce'); ?>
                    <div class="form-group">
                        <label for="snippet_title"><?php esc_html_e('Title:', 'adversarial-code-generator'); ?></label>
                        <input type="text" id="snippet_title" name="snippet_title" class="regular-text" required>
                    </div>
                    <div class="form-group">
                        <label for="snippet_code"><?php esc_html_e('Code:', 'adversarial-code-generator'); ?></label>
                        <div class="code-editor-wrapper snippet-code" data-language="python" data-theme="monokai" style="height: 200px;"></div>
                        <input type="hidden" class="snippet-code-value" name="snippet_code_value" value="">
                    </div>
                    <div class="form-group">
                        <label for="snippet_language"><?php esc_html_e('Language:', 'adversarial-code-generator'); ?></label>
                        <select id="snippet_language" name="snippet_language" class="regular-text">
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
                    <div class="form-group">
                        <label for="snippet_tags"><?php esc_html_e('Tags (comma separated):', 'adversarial-code-generator'); ?></label>
                        <input type="text" id="snippet_tags" name="snippet_tags" class="regular-text">
                    </div>
                    <button type="submit" class="button button-primary"><?php esc_html_e('Save Snippet', 'adversarial-code-generator'); ?></button>
                    <button type="button" class="button cancel-add-snippet"><?php esc_html_e('Cancel', 'adversarial-code-generator'); ?></button>
                </form>
            </div>
        </div>
        <?php
        return ob_get_clean();
    }
}