package biblivre.mail.config;

import biblivre.core.utils.PropertiesUtil;
import biblivre.core.utils.StringPool;
import biblivre.mail.constants.EmailPropertyKeys;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;

import java.util.Properties;

@Configuration
public class MailConfiguration {

    @Bean
    public JavaMailSender getMailSender() {

        JavaMailSenderImpl javaMailSender = new JavaMailSenderImpl();
        javaMailSender.setHost(PropertiesUtil.getConfigFromEnv(EmailPropertyKeys.SPRING_MAIL_HOST, StringPool.BLANK));
        javaMailSender.setPort(Integer.valueOf(PropertiesUtil.getConfigFromEnv(EmailPropertyKeys.SPRING_MAIL_PORT, StringPool.BLANK)));
        javaMailSender.setUsername(PropertiesUtil.getConfigFromEnv(EmailPropertyKeys.SPRING_MAIL_USERNAME, StringPool.BLANK));
        javaMailSender.setPassword(PropertiesUtil.getConfigFromEnv(EmailPropertyKeys.SPRING_MAIL_PASSWORD, StringPool.BLANK));

        Properties javaMailProperties = new Properties();
        javaMailProperties.put(EmailPropertyKeys.SPRING_SMTP_START_TLS_ENABLE, "true");
        javaMailProperties.put(EmailPropertyKeys.SPRING_SMTP_AUTH, "true");
        javaMailProperties.put(EmailPropertyKeys.MAIL_TRANSPORT_PROTOCOL, "smtp");
        javaMailProperties.put(EmailPropertyKeys.MAIL_DEBUG, "true");
        javaMailProperties.put(EmailPropertyKeys.MAIL_SMTP_SSL_TRUST, "*");

        javaMailSender.setJavaMailProperties(javaMailProperties);

        return javaMailSender;
    }
}
