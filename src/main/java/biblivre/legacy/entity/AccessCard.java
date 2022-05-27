package biblivre.legacy.entity;

import biblivre.administration.accesscards.AccessCardStatus;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.PostLoad;
import javax.persistence.Table;
import javax.persistence.Transient;

@Entity
@Table(name = "access_cards", schema = "single")
public class AccessCard extends AuditableEntity {
    @Id private int id;

    @Column private String code;

    @Column(name = "status")
    private String rawAccessCardStatus;

    @Transient private AccessCardStatus accessCardStatus;

    @PostLoad
    private void loadAccessCardStatus() {
        AccessCardStatus.fromString(rawAccessCardStatus);
    }

    public int getId() {
        return this.id;
    }

    public String getCode() {
        return this.code;
    }

    public AccessCardStatus getAccessCardStatus() {
        return this.accessCardStatus;
    }

    public void setAcessCardStatus(AccessCardStatus accessCardStatus) {
        this.accessCardStatus = accessCardStatus;

        this.rawAccessCardStatus = accessCardStatus.name().toLowerCase();
    }

    public void setId(int id) {
        this.id = id;
    }

    public void setCode(String code) {
        this.code = code;
    }
}
