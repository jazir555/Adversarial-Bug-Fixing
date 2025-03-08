class TranslationSupport {
    private $translation_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->translation_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/translations';
        wp_mkdir_p($this->translation_dir);
    }

    public function translate_code($code, $source_lang, $target_lang) {
        $prompt = "Translate the following " . $source_lang . " code to " . $target_lang . ":\n\n" . $code;
        
        $llm_handler = new LLMHandler();
        return $llm_handler->call_llm_api($llm_handler->select_model('translation'), $prompt, 'translate_code');
    }

    public function save_translation($original_code, $translated_code, $source_lang, $target_lang) {
        $translation = [
            'source_lang' => $source_lang,
            'target_lang' => $target_lang,
            'original_code' => $original_code,
            'translated_code' => $translated_code,
            'date' => current_time('mysql')
        ];
        
        $filename = uniqid('translation_') . '.json';
        file_put_contents($this->translation_dir . '/' . $filename, wp_json_encode($translation));
        
        return $filename;
    }

    public function get_recent_translations($limit = 10) {
        $translations = [];
        $translation_files = glob($this->translation_dir . '/*.json');
        
        usort($translation_files, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        foreach (array_slice($translation_files, 0, $limit) as $file) {
            $content = file_get_contents($file);
            $translations[] = json_decode($content, true);
        }
        
        return $translations;
    }
}