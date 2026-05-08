# Projekt-5-monitoring

En automatiserad infrastruktur för övervakning, driftsatt med Vagrant och konfigurerad via en dedikerad kontrollnod med Ansible. Systemet övervakar två målnoder med hjälp av Prometheus och Grafana.

---

## Innehållsförteckning

- [Arkitektur](#arkitektur)
- [Miljöer och IP-adresser](#miljöer-och-ip-adresser)
- [Mappstruktur](#mappstruktur)
- [Komponenter](#komponenter)
- [Krav och förutsättningar](#krav-och-förutsättningar)
- [Kom igång](#kom-igång)
- [Secrets](#secrets)
- [Säkerhetsanalys & Åtgärder](#säkerhetsanalys--åtgärder)
- [Designval och motivering](#designval-och-motivering)

---

## Arkitektur

```text
Windows-laptop (host)
        |
┌───────▼────────────────────────────────────────────┐
│           Privat nätverk 192.168.56.0/24           │
│                                                    │
│  ┌────────────────┐         ┌───────────────────┐  │
│  │   control      │         │   monitor         │  │
│  │  192.168.56.10 │         │  192.168.56.11    │  │
│  │  (Ansible)     │         │ (Prometheus, osv) │  │
│  └───────┬────────┘         └─────────┬─────────┘  │
│          │ SSH                        │            │
│          │                            │ Hämtar metrics
│    ┌─────┴──────┐                     │            │
│    ▼            ▼                     ▼            │
│ ┌─────────┐  ┌─────────┐   <──────────┘            │
│ │ server1 │  │ server2 │                           │
│ │   .12   │  │   .13   │                           │
│ └─────────┘  └─────────┘                           │
└────────────────────────────────────────────────────┘
```

---

## Miljöer och IP-adresser

| VM | Roll | IP-adress | Beskrivning |
|---|---|---|---|
| `control` | Kontrollnod | 192.168.56.10 | Kör Ansible-playbooks mot de andra maskinerna |
| `monitor` | Övervakning | 192.168.56.11 | Värd för Prometheus och Grafana |
| `server1` | Målnod | 192.168.56.12 | Tjänsteserver som exporterar metrics |
| `server2` | Målnod | 192.168.56.13 | Tjänsteserver som exporterar metrics |

---

## Mappstruktur

```text
repo/
├── vagrant/
│   ├── Vagrantfile          # Sätter upp servrarna i VirtualBox
│   └── secrets.yml          # Variabler som är hemliga (t.ex. lösenord)
│
├── ansible/
│   ├── inventory.ini        # Berättar för Ansible var servrarna finns
│   ├── site.yml             # Huvudfilen (playbooken) som kör allt
│   └── roles/               # Separata mappar för prometheus, grafana osv.
└── README.md
```

---

## Komponenter

### Vagrantfile
Definierar fyra virtuella maskiner i ett privat nätverk (192.168.56.0/24). Det är denna fil som körs när vi skriver `vagrant up`.

### site.yml
Ansibles master playbook. Den bestämmer vad som installeras var:
1. Den lägger in `node_exporter` på alla servrar för att samla in data.
2. Den lägger in `prometheus` och `grafana` på vår `monitor`-server för att spara och visa datan.

---

## Krav och förutsättningar

För att kunna köra det här projektet på din dator behöver du:

- **VirtualBox**: För att köra de virtuella maskinerna.
- **Vagrant**: För att bygga och starta maskinerna automatiskt.
- Minst 8 GB RAM (fyra virtuella maskiner kräver lite minne).

---

## Kom igång

Så här startar du hela övervakningsmiljön från noll:

```bash
# 1. Starta alla fyra maskinerna (detta tar några minuter första gången)
vagrant up

# 2. Logga in på kontrollnoden
vagrant ssh control

# 3. Kör Ansible-playbooken för att installera all mjukvara
cd /project/ansible
ansible-playbook site.yml
```

Efter detta körs Prometheus och Grafana på `monitor`-servern, och samlar in data från de andra maskinerna.

---

## Secrets

I mappen `vagrant/` finns en fil som heter `secrets.yml`. Den är tänkt att innehålla känsliga variabler (som till exempel lösenordet till Grafana). 
> **Viktigt:** Denna fil är tillagd i `.gitignore` och ska aldrig laddas upp till GitHub!

---

## Säkerhetsanalys & Åtgärder

Eftersom detta är en testmiljö (ett lokalt privat nätverk) har säkerheten anpassats därefter:

- **Nätverk**: Alla maskiner ligger på ett privat nätverk (`192.168.56.0/24`). De är inte exponerade mot internet.
- **Åtkomst**: Inloggning sker enbart via SSH-nycklar (hanteras automatiskt av Vagrant).
- **Framtida förbättringar**: Om detta skulle driftas i produktion hade vi behövt sätta upp en brandvägg (UFW) och använda HTTPS för Grafana-webbgränssnittet.

---

## Designval och motivering

### Varför en separat kontrollnod?
Läraren ställde detta som ett krav för att simulera hur en "jump host" eller dedikerad Ansible-server fungerar i verkligheten. Det gör också att vi inte behöver installera Ansible eller Python på värddatorn (Windows).

### Varför separat monitor-server?
Genom att separera övervakningen (`monitor`) från tjänsteservrarna (`server1` och `server2`) ser vi till att om en tjänsteserver kraschar av hög belastning, så överlever fortfarande övervakningsservern och kan larma om kraschen.