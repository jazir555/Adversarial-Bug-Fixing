class Sandbox {
    private $sandbox_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->sandbox_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/sandbox';
        wp_mkdir_p($this->sandbox_dir);
    }
    
    public function execute_code($code, $language = 'python') {
        $this->validate_code($code, $language);
        
        $temp_file = $this->create_temp_file($code, $language);
        $output = $this->run_in_sandbox($temp_file, $language);
        $this->cleanup_temp_file($temp_file);
        
        return $output;
    }
    
    private function validate_code($code, $language) {
        $security = new Security();
        $security->sanitize_code($code);
        
        $settings = new Settings();
        $timeout = $settings->get('code_execution_timeout') ?: 30;
        
        if ($timeout < 5 || $timeout > 120) {
            throw new Exception("Invalid execution timeout setting");
        }
    }
    
    private function create_temp_file($code, $language) {
        $extension = match ($language) {
            'python' => 'py',
            'javascript' => 'js',
            'java' => 'java',
            'php' => 'php',
            'cpp' => 'cpp',
            'csharp' => 'cs',
            'go' => 'go',
            'ruby' => 'rb',
            default => 'txt'
        };
        
        $temp_file = tempnam($this->sandbox_dir, 'code_') . ".$extension";
        file_put_contents($temp_file, $code);
        
        return $temp_file;
    }
    
    private function run_in_sandbox($file_path, $language) {
        $settings = new Settings();
        $timeout = $settings->get('code_execution_timeout') ?: 30;
        
        $descriptorspec = [
            0 => ['pipe', 'r'],  // stdin
            1 => ['pipe', 'w'],  // stdout
            2 => ['pipe', 'w']   // stderr
        ];
        
        $process = proc_open($this->get_command($file_path, $language), $descriptorspec, $pipes);
        
        if (!is_resource($process)) {
            throw new Exception("Failed to start process");
        }
        
        fclose($pipes[0]);
        
        $stdout = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        
        $stderr = stream_get_contents($pipes[2]);
        fclose($pipes[2]);
        
        $return_code = proc_close($process);
        
        if ($return_code !== 0 || !empty($stderr)) {
            throw new Exception("Execution failed: " . $stderr);
        }
        
        return $stdout;
    }
    
    private function get_command($file_path, $language) {
        return match ($language) {
            'python' => "python3 $file_path",
            'javascript' => "node $file_path",
            'java' => "java " . escapeshellarg(basename($file_path, '.java')),
            'php' => "php $file_path",
            'cpp' => "g++ -o " . escapeshellarg(dirname($file_path)) . "/output " . escapeshellarg($file_path) . " && " . dirname($file_path) . "/output",
            'csharp' => "mcs $file_path && mono " . escapeshellarg(dirname($file_path) . "/output.exe"),
            'go' => "go run $file_path",
            'ruby' => "ruby $file_path",
            default => throw new Exception("Unsupported language")
        };
    }
    
    private function cleanup_temp_file($file_path) {
        if (file_exists($file_path)) {
            unlink($file_path);
        }
        
        $base_name = pathinfo($file_path, PATHINFO_FILENAME);
        $directory = dirname($file_path);
        
        // Clean up any compiled files
        if ($language === 'cpp') {
            $output_file = "$directory/output";
            if (file_exists($output_file)) {
                unlink($output_file);
            }
        } elseif ($language === 'csharp') {
            $output_file = "$directory/output.exe";
            if (file_exists($output_file)) {
                unlink($output_file);
            }
        }
    }
}