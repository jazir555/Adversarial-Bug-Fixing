class RealTimeCollaboration {
    private $collaboration_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->collaboration_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/collaboration';
        wp_mkdir_p($this->collaboration_dir);
    }

    public function create_collaboration_session($project_name, $initial_code = '') {
        $session_id = uniqid('collab_');
        $session_dir = $this->collaboration_dir . '/' . $session_id;
        wp_mkdir_p($session_dir);
        
        file_put_contents($session_dir . '/code.txt', $initial_code);
        file_put_contents($session_dir . '/metadata.json', wp_json_encode([
            'project_name' => $project_name,
            'created_at' => current_time('mysql'),
            'participants' => []
        ]));
        
        return $session_id;
    }

    public function get_collaboration_session($session_id) {
        $session_dir = $this->collaboration_dir . '/' . $session_id;
        
        if (!file_exists($session_dir)) {
            return null;
        }
        
        $code = file_get_contents($session_dir . '/code.txt');
        $metadata = json_decode(file_get_contents($session_dir . '/metadata.json'), true);
        
        return [
            'code' => $code,
            'metadata' => $metadata
        ];
    }

    public function update_collaboration_session($session_id, $new_code, $user_id) {
        $session_dir = $this->collaboration_dir . '/' . $session_id;
        
        if (!file_exists($session_dir)) {
            return false;
        }
        
        file_put_contents($session_dir . '/code.txt', $new_code);
        
        $metadata = json_decode(file_get_contents($session_dir . '/metadata.json'), true);
        $metadata['participants'][] = [
            'user_id' => $user_id,
            'updated_at' => current_time('mysql'),
            'changes' => $new_code
        ];
        
        file_put_contents($session_dir . '/metadata.json', wp_json_encode($metadata));
        
        return true;
    }

    public function list_collaboration_sessions($limit = 20) {
        $sessions = [];
        $session_dirs = glob($this->collaboration_dir . '/*', GLOB_ONLYDIR);
        
        usort($session_dirs, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        foreach (array_slice($session_dirs, 0, $limit) as $dir) {
            $metadata = json_decode(file_get_contents($dir . '/metadata.json'), true);
            $sessions[] = [
                'id' => basename($dir),
                'project_name' => $metadata['project_name'],
                'created_at' => $metadata['created_at'],
                'last_updated' => filemtime($dir)
            ];
        }
        
        return $sessions;
    }
}