class CIIntegration {
    private $pipelines_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->pipelines_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/ci_pipelines';
        wp_mkdir_p($this->pipelines_dir);
    }

    public function create_pipeline($name, $config) {
        $pipeline_id = uniqid('pipeline_');
        $pipeline_dir = "$this->pipelines_dir/$pipeline_id";
        wp_mkdir_p($pipeline_dir);
        
        file_put_contents("$pipeline_dir/config.json", wp_json_encode($config));
        
        return $pipeline_id;
    }

    public function get_pipeline($pipeline_id) {
        $pipeline_dir = "$this->pipelines_dir/$pipeline_id";
        if (!file_exists($pipeline_dir)) {
            return null;
        }
        
        return json_decode(file_get_contents("$pipeline_dir/config.json"), true);
    }

    public function run_pipeline($pipeline_id) {
        $pipeline = $this->get_pipeline($pipeline_id);
        if (!$pipeline) {
            return false;
        }
        
        // Implement pipeline execution logic
        // This would typically involve:
        // 1. Cloning the repository
        // 2. Running tests
        // 3. Building the project
        // 4. Deploying if successful
        
        // For demonstration purposes, we'll just return a success status
        return true;
    }

    public function list_pipelines($limit = 20) {
        $pipeline_dirs = glob("$this->pipelines_dir/*", GLOB_ONLYDIR);
        usort($pipeline_dirs, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        $pipelines = [];
        foreach (array_slice($pipeline_dirs, 0, $limit) as $dir) {
            $config = json_decode(file_get_contents("$dir/config.json"), true);
            $pipelines[] = [
                'id' => basename($dir),
                'name' => $config['name'],
                'repository' => $config['repository'],
                'branch' => $config['branch'],
                'last_run' => isset($config['last_run']) ? $config['last_run'] : null
            ];
        }
        
        return $pipelines;
    }
}