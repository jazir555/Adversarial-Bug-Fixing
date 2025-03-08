class Exporter {
    public function export($version_id, $format = 'zip') {
        try {
            $version = VersionControl::get_instance()->get_version($version_id);
            
            switch ($format) {
                case 'zip':
                    return $this->export_as_zip($version);
                case 'github':
                    return $this->export_to_github($version);
                default:
                    throw new Exception("Unsupported export format: $format");
            }
        } catch (Exception $e) {
            throw new Exception("Export failed: " . $e->getMessage());
        }
    }
    
    private function export_as_zip($version) {
        // Create a temporary directory
        $temp_dir = wp_tempnam();
        wp_mkdir_p($temp_dir);
        
        // Create directory structure
        $project_dir = $temp_dir . '/project';
        wp_mkdir_p($project_dir);
        
        // Save code file
        $file_name = $project_dir . '/code.' . $version['language'];
        file_put_contents($file_name, $version['code']);
        
        // Create zip archive
        $zip = new ZipArchive();
        $zip_file = $temp_dir . '/project.zip';
        
        if ($zip->open($zip_file, ZipArchive::CREATE) !== TRUE) {
            throw new Exception("Failed to create zip archive");
        }
        
        $zip->addGlob($project_dir . '/*');
        $zip->close();
        
        // Read zip file contents
        $zip_contents = file_get_contents($zip_file);
        
        // Clean up
        wp_rmdir($temp_dir);
        
        return [
            'filename' => 'code-export-' . date('Ymd-His') . '.zip',
            'contents' => $zip_contents
        ];
    }
    
    private function export_to_github($version) {
        // Implement GitHub export logic
        // This would typically involve creating a repository and uploading files
        // For this example, we'll just return a placeholder response
        return [
            'repository_url' => 'https://github.com/yourusername/yourrepository',
            'commit_hash' => 'abc123'
        ];
    }
}