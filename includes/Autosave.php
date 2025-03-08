class AutoSave {
    private $autosave_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->autosave_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/autosaves';
        wp_mkdir_p($this->autosave_dir);
        
        add_action('adversarial_code_autosave', [$this, 'handle_autosave']);
    }

    public function handle_autosave($data) {
        $user_id = get_current_user_id();
        $session_id = uniqid('autosave_');
        
        $autosave_data = [
            'code' => $data['code'],
            'language' => $data['language'],
            'prompt' => $data['prompt'],
            'timestamp' => current_time('mysql')
        ];
        
        file_put_contents("{$this->autosave_dir}/{$user_id}_{$session_id}.json", wp_json_encode($autosave_data));
        
        return [
            'session_id' => $session_id,
            'message' => 'Autosave successful'
        ];
    }

    public function get_autosaves($user_id, $limit = 5) {
        $user_autosaves = glob("{$this->autosave_dir}/{$user_id}_*.json");
        usort($user_autosaves, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        $autosaves = [];
        foreach (array_slice($user_autosaves, 0, $limit) as $file) {
            $data = json_decode(file_get_contents($file), true);
            $autosaves[] = [
                'id' => basename($file, '.json'),
                'code' => $data['code'],
                'language' => $data['language'],
                'prompt' => $data['prompt'],
                'timestamp' => $data['timestamp']
            ];
        }
        
        return $autosaves;
    }

    public function delete_autosave($autosave_id) {
        $file = "{$this->autosave_dir}/{$autosave_id}.json";
        if (file_exists($file)) {
            unlink($file);
            return true;
        }
        return false;
    }
}