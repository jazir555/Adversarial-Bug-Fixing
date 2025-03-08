class CodeEnvironment {
    private $environments_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->environments_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/environments';
        wp_mkdir_p($this->environments_dir);
    }

    public function create_environment($name, $language, $dependencies = []) {
        $env_id = uniqid('env_');
        $env_dir = "$this->environments_dir/$env_id";
        wp_mkdir_p($env_dir);
        
        file_put_contents("$env_dir/config.json", wp_json_encode([
            'name' => $name,
            'language' => $language,
            'dependencies' => $dependencies,
            'created_at' => current_time('mysql')
        ]));
        
        return $env_id;
    }

    public function get_environment($env_id) {
        $env_dir = "$this->environments_dir/$env_id";
        if (!file_exists($env_dir)) {
            return null;
        }
        
        return json_decode(file_get_contents("$env_dir/config.json"), true);
    }

    public function update_environment($env_id, $dependencies) {
        $env_dir = "$this->environments_dir/$env_id";
        if (!file_exists($env_dir)) {
            return false;
        }
        
        $config = json_decode(file_get_contents("$env_dir/config.json"), true);
        $config['dependencies'] = $dependencies;
        
        file_put_contents("$env_dir/config.json", wp_json_encode($config));
        return true;
    }

    public function delete_environment($env_id) {
        $env_dir = "$this->environments_dir/$env_id";
        if (file_exists($env_dir)) {
            wp_delete_dir($env_dir);
            return true;
        }
        return false;
    }

    public function list_environments($limit = 20) {
        $env_dirs = glob("$this->environments_dir/*", GLOB_ONLYDIR);
        usort($env_dirs, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        $environments = [];
        foreach (array_slice($env_dirs, 0, $limit) as $dir) {
            $config = json_decode(file_get_contents("$dir/config.json"), true);
            $environments[] = [
                'id' => basename($dir),
                'name' => $config['name'],
                'language' => $config['language'],
                'dependencies' => $config['dependencies'],
                'created_at' => $config['created_at']
            ];
        }
        
        return $environments;
    }
}