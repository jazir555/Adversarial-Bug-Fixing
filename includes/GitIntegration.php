class GitIntegration {
    private $repos_dir;
    
    public function __construct() {
        $upload_dir = wp_upload_dir();
        $this->repos_dir = trailingslashit($upload_dir['basedir']) . 'adversarial-code-generator/git_repos';
        wp_mkdir_p($this->repos_dir);
    }
    
    public function clone_repository($repo_url, $branch = 'main') {
        $repo_name = basename(parse_url($repo_url, PHP_URL_PATH));
        $repo_dir = "$this->repos_dir/$repo_name";
        
        if (!file_exists($repo_dir)) {
            exec("git clone --branch $branch $repo_url $repo_dir", $output, $return_var);
            
            if ($return_var !== 0) {
                throw new Exception("Failed to clone repository: " . implode("\n", $output));
            }
        }
        
        return $repo_dir;
    }
    
    public function commit_changes($repo_dir, $message, $files = []) {
        if (!file_exists($repo_dir)) {
            throw new Exception("Repository directory does not exist");
        }
        
        chdir($repo_dir);
        
        if (!empty($files)) {
            exec("git add " . implode(' ', $files), $output, $return_var);
        } else {
            exec("git add .", $output, $return_var);
        }
        
        if ($return_var !== 0) {
            throw new Exception("Failed to add files: " . implode("\n", $output));
        }
        
        exec("git commit -m \"$message\"", $output, $return_var);
        
        if ($return_var !== 0) {
            throw new Exception("Failed to commit changes: " . implode("\n", $output));
        }
        
        return true;
    }
    
    public function push_changes($repo_dir) {
        if (!file_exists($repo_dir)) {
            throw new Exception("Repository directory does not exist");
        }
        
        chdir($repo_dir);
        exec("git push", $output, $return_var);
        
        if ($return_var !== 0) {
            throw new Exception("Failed to push changes: " . implode("\n", $output));
        }
        
        return true;
    }
    
    public function get_repository_status($repo_dir) {
        if (!file_exists($repo_dir)) {
            throw new Exception("Repository directory does not exist");
        }
        
        chdir($repo_dir);
        exec("git status --porcelain", $output);
        
        return $output;
    }
}