class Security {
    private $disallowed_imports = ['os', 'subprocess', 'sys', 'shutil'];
    private $disallowed_functions = ['eval', 'exec', 'system', 'popen'];
    private $max_line_length = 150;
    private $max_code_length = 10000;
    
    public function sanitize_prompt($prompt) {
        // Basic sanitization to prevent injection attacks
        $prompt = wp_kses_post($prompt);
        $prompt = str_replace(['`', '$', '\\'], '', $prompt);
        return trim($prompt);
    }
    
    public function sanitize_code($code) {
        // Remove potentially dangerous patterns
        foreach ($this->disallowed_imports as $import) {
            $code = preg_replace('/^import\s+' . $import . '/mi', '', $code);
            $code = preg_replace('/^from\s+' . $import . '\s+import/mi', '', $code);
        }
        
        foreach ($this->disallowed_functions as $func) {
            $code = preg_replace('/\b' . $func . '\s*\(/', '', $code);
        }
        
        // Limit code size
        if (strlen($code) > $this->max_code_length) {
            throw new Exception('Code exceeds maximum allowed length');
        }
        
        return $code;
    }
    
    public function check_code_security($code) {
        $issues = [];
        
        // Check for dangerous imports
        foreach ($this->disallowed_imports as $import) {
            if (preg_match('/^import\s+' . $import . '/mi', $code) || 
                preg_match('/^from\s+' . $import . '\s+import/mi', $code)) {
                $issues[] = "Use of disallowed import '$import'";
            }
        }
        
        // Check for dangerous functions
        foreach ($this->disallowed_functions as $func) {
            if (preg_match('/\b' . $func . '\s*\(/', $code)) {
                $issues[] = "Use of dangerous function '$func'";
            }
        }
        
        // Check for shell injections
        if (preg_match('/(os\.system|subprocess\.call|subprocess\.Popen)/', $code)) {
            $issues[] = "Potential shell injection vulnerability";
        }
        
        // Check for overly long lines
        $lines = explode("\n", $code);
        foreach ($lines as $line) {
            if (strlen(trim($line)) > $this->max_line_length) {
                $issues[] = "Line exceeds maximum allowed length";
                break;
            }
        }
        
        return $issues;
    }
}