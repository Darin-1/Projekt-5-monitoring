# Projekt-5-monitoring

> En automatiserad infrastruktur för övervakning, driftsatt med Vagrant och konfigurerad via en dedikerad kontrollnod med Ansible. Systemet övervakar två målnoder med hjälp av Prometheus och Grafana.

---

## Innehållsförteckning

- [Arkitektur](#arkitektur)
- [Miljöer och IP-adresser](#miljöer-och-ip-adresser)
- [Mappstruktur](#mappstruktur)
- [Komponenter](#komponenter)
- [Krav och förutsättningar](#krav-och-förutsättningar)
- [Kom igång](#kom-igång)
- [Secrets](#secrets)
- [Säkerhetsåtgärder](#säkerhetsåtgärder)
- [Säkerhetsanalys](#säkerhetsanalys)
- [Verifiering](#verifiering)
- [Designval och motivering](#designval-och-motivering)

---

## Arkitektur

```text
Windows-laptop (host)
        |
┌───────▼────────────────────────────────────────────┐
│           Privat nätverk 192.168.56.0/24           │
│                                                    │
│               ┌────────────────┐                   │
│               │   control      │                   │
│               │  192.168.56.10 │                   │
│               │  (Ansible)     │                   │
│               └─┬─────┬──────┬─┘                   │
│                 │     │      │ SSH                 │
│      ┌──────────┘     │      └──────────┐          │
│      ▼                ▼                 ▼          │
│ ┌──────────┐    ┌──────────┐      ┌─────┴───────┐  │
│ │ server1  │    │ server2  │      │   monitor   │  │
│ │   .12    │    │   .13    │      │    .11      │  │
│ └────▲─────┘    └────▲─────┘      └─────▲───┬───┘  │
│      │               │   Hämtar metrics │   │      │
│      └───────────────┴──────────────────┴───┘      │
└────────────────────────────────────────────────────┘
```

---

## Miljöer och IP-adresser

| VM | Roll | IP-adress | Port forwarding | Beskrivning |
|---|---|---|---|---|
| `control` | Kontrollnod | 192.168.56.10 | — | Kör Ansible-playbooks mot de andra maskinerna |
| `monitor` | Övervakning | 192.168.56.11 | — | Värd för Prometheus och Grafana |
| `server1` | Målnod | 192.168.56.12 | — | Tjänsteserver som exporterar metrics |
| `server2` | Målnod | 192.168.56.13 | — | Tjänsteserver som exporterar metrics |

---

## Mappstruktur

```text
repo/
├── vagrant/
│   ├── Vagrantfile          # Sätter upp servrarna i VirtualBox
│   └── secrets.yml          # GITIGNORERAD — Variabler som är hemliga (t.ex. lösenord)
│
├── ansible/
│   ├── inventory.ini        # Berättar för Ansible var servrarna finns
│   ├── site.yml             # Huvudfilen (master playbook) som kör allt
│   │
│   └── roles/               # Separata mappar för prometheus, grafana osv.
│       ├── grafana/
│       ├── node_exporter/
│       └── prometheus/
│
├── verify.ps1               # Verifieringsskript (PowerShell)
├── .gitignore
└── README.md
```

---

## Komponenter

### Vagrantfile

Definierar fyra virtuella maskiner i VirtualBox med ett gemensamt host-only-nätverk (`192.168.56.0/24`). `control`-noden får repot monterat via en synced_folder (`../` till `/project`) så att Ansible kan köras från den.

### ansible/inventory.ini

Grupperar servrarna i `[monitoring]` och `[targets]`. Anger IP-adresser och pekar ut specifika SSH-nycklar för att Ansible ska kunna ansluta lösenordslöst till övriga noder.

### ansible/site.yml

Master playbook med två plays:
1. **Install Node Exporter on all nodes** — installerar `node_exporter`-rollen på samtliga noder (`hosts: all`) så att metrics kan samlas in överallt.
2. **Install monitoring stack** — installerar `prometheus`- och `grafana`-rollerna på övervakningsservern (`hosts: monitoring`).

### Rollen node_exporter

Installerar Prometheus Node Exporter på alla maskiner, vilket exponerar hårdvaru- och OS-metrik på port 9100.

### Rollen prometheus

Installerar Prometheus-servern på `monitor`-noden. Den skrapar kontinuerligt metrik från alla Node Exporters.

### Rollen grafana

Installerar Grafana på `monitor`-noden för att visualisera metrics insamlade av Prometheus. Konfigureras via Ansible för att automatiskt ha Prometheus som Data Source och Node Exporter som dashboard (Provisioning).

---

## Krav och förutsättningar

**Programvara som måste vara installerad på Windows-hosten:**

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)
- [Git](https://git-scm.com/)
- PowerShell (för att köra verifieringsskriptet)

**Hårdvarukrav:**

- Minst 8 GB RAM (fyra virtuella maskiner kräver lite minne)

**Secrets-fil:**

Skapa filen `vagrant/secrets.yml` med nödvändiga hemligheter innan du kör `vagrant up`.

---

## Kom igång

Så här startar du hela övervakningsmiljön från noll:

```bash
# 1. Starta alla fyra maskinerna (detta tar några minuter första gången)
cd vagrant
vagrant up

# 2. Logga in på kontrollnoden
vagrant ssh control

# 3. Kör Ansible-playbooken för att installera all mjukvara
cd /project/ansible
ansible-playbook site.yml

# 4. Verifiera miljön
# I ett PowerShell-fönster på host-maskinen i roten av repot
.\verify.ps1
```

**Förväntat slutresultat:**

Öppna `http://192.168.56.11:3000` i webbläsaren. Du ska nå Grafana-webbgränssnittet. Öppna `http://192.168.56.11:9090` för att nå Prometheus.

---

## Secrets

Filen `vagrant/secrets.yml` måste skapas lokalt och **ska aldrig committas till Git** (den finns i `.gitignore`).
Denna fil innehåller känsliga variabler som till exempel lösenordet till Grafana.

---

## Säkerhetsåtgärder

Följande säkerhetsåtgärder är implementerade och automatiserade i miljön:

| Åtgärd | Var | Hur verifieras det |
|---|---|---|
| Inloggning enbart via SSH-nycklar (hanteras av Vagrant) | Alla VMs | Default Vagrant-beteende, `inventory.ini` pekar på dessa. |
| Secrets utanför Git | Alla | `git log --all -- vagrant/secrets.yml` (tom output) |

---

## Säkerhetsanalys

### Kvarvarande brister

**Brist 1: Ingen kryptering på interna nätverket (HTTP används)**

Trafiken mellan Grafana, Prometheus och Node Exporters skickas okrypterat via HTTP. Grafana-webbgränssnittet nås också via okrypterad HTTP (port 3000).

*Åtgärd:* Konfigurera TLS/HTTPS för webbgränssnittet (Grafana/Prometheus) samt kryptering internt för Prometheus-skrapning.

*Accepterat i denna miljö eftersom:* Miljön körs på ett stängt Host-Only nätverk (`192.168.56.0/24`) utan exponering mot internet.

**Brist 2: Avsaknad av brandväggsregler (t.ex. UFW)**

Inga specifika portar begränsas; alla portar (inkl. 9090, 3000, 9100) är öppna internt på nätverket.

*Åtgärd:* Installera och konfigurera UFW via Ansible så att enbart portar som krävs är öppna (t.ex. begränsa tillgången till Node Exporter port 9100 enbart till `monitor`-nodens IP).


Brist 3: Single Point of Failure (SPOF) för övervakningen
Alla centrala övervakningskomponenter (Prometheus och Grafana) körs på en och samma maskin, monitor servern. Om operativsystemet på den servern kraschar, stannar all övervakning omedelbart och vi blir helt blinda för fel i systemet.


Brist 4: Öppen åtkomst utan autentisering (inloggning)
Prometheus databas (port 9090) och Node Exporter (port 9100) saknar lösenordsskydd. Vem som helst med tillgång till nätverket kan läsa all serverdata, eller medvetet köra orimligt tunga sökningar i databasen tills hela servern kraschar av överbelastning.

Brist 5: Ingen backup av historisk data
Det saknas rutiner för att ta säkerhetskopior. All insamlad systemdata ligger enbart lokalt på monitor serverns virtuella disk. Om denna disk blir korrupt förloras all historisk data permanent.


---

## Verifiering

Kör det automatiserade verifieringsskriptet från Windows-hosten:

```powershell
.\verify.ps1
```

Skriptet kontrollerar:

- Att Prometheus på `monitor` svarar på HTTP 200 via `/-/healthy`
- Att Grafana på `monitor` svarar på HTTP 200 via `/api/health`
- Att Node Exporter på `server1` svarar på HTTP 200 via `/metrics`
- Att Node Exporter på `server2` svarar på HTTP 200 via `/metrics`

---

## Designval och motivering

### Varför en separat kontrollnod?

Att ha en separat kontrollnod (`control`) simulerar hur en "jump host" eller dedikerad Ansible-server fungerar i en verklig produktionsmiljö. Det eliminerar också behovet att installera Ansible eller Python på host-datorn (Windows).

### Varför separat monitor-server?

Genom att separera övervakningen (`monitor`) från tjänsteservrarna (`server1` och `server2`) ser vi till att om en tjänsteserver kraschar av hög belastning eller ett fel, så är övervakningsplattformen fortfarande uppe och kan larma om incidenten. En övervakning som körs på samma server som applikationen den övervakar fallerar ofta samtidigt som applikationen.

### Automatisering av Dashboards (Grafana Provisioning)

Istället för att manuellt klicka i webbgränssnittet för att lägga till Prometheus som datakälla och importera dashbords, används Ansible för att ladda upp förkonfigurerade mallar för Data Sources och Dashboards. Detta säkerställer en "Infrastructure as Code"-princip, vilket gör hela övervakningen operativ direkt efter provisionering.

### Användning av Ansible Handlers

För att undvika onödiga omstarter av tjänster (som Prometheus och Grafana) använder Ansible Handlers. Tjänsterna startas endast om när konfigurationsfiler modifieras, vilket ökar stabiliteten under playbook-körningar.
