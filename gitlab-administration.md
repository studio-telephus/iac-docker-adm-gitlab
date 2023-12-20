# Gitlab administration 

## Apache2

    <VirtualHost *:443>
        ServerName telephus.k-space.ee
    
        Protocols h2 http/1.1
        
        <If "%{HTTP_HOST} == 'www.telephus.k-space.ee'">
            Redirect permanent / https://telephus.k-space.ee/
        </If>
        
        DocumentRoot /var/www/telephus.k-space.ee/public_html
        ErrorLog ${APACHE_LOG_DIR}/telephus.k-space.ee-error.log
        CustomLog ${APACHE_LOG_DIR}/telephus.k-space.ee-access.log combined
        
        SSLEngine On
        SSLCertificateFile /etc/letsencrypt/live/telephus.k-space.ee/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/telephus.k-space.ee/privkey.pem
        
        # Other Apache Configuration
        ProxyPreserveHost On
        ProxyRequests Off
        SSLProxyEngine on
    
        ProxyPass /gitlab https://10.0.10.121:443/gitlab
        ProxyPassReverse /gitlab https://10.0.10.121:443/gitlab
    
    </VirtualHost>

## Upgrading Gitlab

[Upgrading GitLab](https://docs.gitlab.com/ee/update/index.html#upgrade-paths) is a relatively straightforward process, but the complexity can increase based on the installation method you have used, how old your GitLab version is, if you’re upgrading to a major version, and so on.

### Manual upgrade using upgrade paths

Check for available GitLab releases

    apt update && apt list -a gitlab-ce

Follow the appropriate upgrade path from the documentation

    apt install gitlab-ce=14.1.0-ce.0

Restart

    gitlab-ctl restart

If you need to roll back to the previous version you can use the database backup made during the upgrade.

