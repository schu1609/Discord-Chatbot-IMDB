Voordat je dit programma kan starten moet je een Discord bot token hebben.

Hier beneden zie je stappenplan hoe deze kan worden opgehaald.

1. Maak een Discord-account aan: Als je er nog geen hebt, maak dan een Discord-account aan op discord.com.

2. Maak een nieuwe applicatie aan: Ga naar de Discord Developer Portal (https://discord.com/developers/applications) en log in met je Discord-account. Klik vervolgens op "New Application" om een nieuwe applicatie aan te maken.

3. Configureer je applicatie: Geef je applicatie een naam en sla de wijzigingen op. Je kunt ook een beschrijving, icoon en andere opties toevoegen.

4. Maak een botgebruiker aan: Ga naar het tabblad "Bot" in de instellingen van je applicatie en klik op "Add Bot". Bevestig je actie. Dit genereert een token voor je bot, dat nodig is om verbinding te maken met de Discord API.

5. Voeg je bot toe aan je Discord-server: Klik op "OAuth2" in de instellingen van je applicatie en vink de benodigde rechten aan (bijvoorbeeld "bot" om een bot toe te voegen aan een server). Kopieer vervolgens de gegenereerde OAuth2-URL en plak deze in je webbrowser. Kies de server waar je de bot aan wilt toevoegen en volg de instructies om de bot aan je server toe te voegen.

6. Gebruik de token die je hebt gekregen bij het maken van je bot om verbinding te maken met de Discord API vanuit je code. Dit stelt je bot in staat om berichten te lezen en te verzenden, gebruikers te beheren, enzovoort.

7. Maak een Json bestand aan met de naam discord_key.json in de Chatbot folder en geef deze bestand de property your_key. bij de property your_key vul je de Discord bot token in.
voorbeeld: { "your_key": "Jou Discord Key" }

Als deze stappen goed zijn uitgevoerd zal de applicatie zonder problemen moeten opstarten.