const axios = require('axios');
const fs = require('fs');
const path = require('path');

const EPG_SOURCES = [
    'https://github.com/limaalef/BrazilTVEPG/raw/main/epg.xml',
    'https://iptv-org.github.io/epg/guides/br.xml',
    'https://github.com/limaalef/BrazilTVEPG/raw/main/claro.xml',
    'https://github.com/limaalef/BrazilTVEPG/raw/main/globo.xml',
    'http://bit.ly/EPG-BR1'
];

const OUTPUT_FILE = 'epg_final.xml';

async function baixarComRedundancia() {
    console.log(`[${new Date().toISOString()}] Iniciando verificação...`);
    let sucesso = false;

    for (let i = 0; i < EPG_SOURCES.length; i++) {
        const url = EPG_SOURCES[i];
        try {
            const response = await axios({
                method: 'get',
                url: url,
                timeout: 30000,
                responseType: 'stream'
            });

            const writer = fs.createWriteStream(path.resolve(__dirname, OUTPUT_FILE));
            response.data.pipe(writer);

            await new Promise((resolve, reject) => {
                writer.on('finish', resolve);
                writer.on('error', reject);
            });

            console.log(`✅ Sucesso! Fonte ${i + 1}`);
            sucesso = true;
            break; 
        } catch (error) {
            console.error(`⚠️ Fonte ${i + 1} falhou.`);
        }
    }
    if (!sucesso) process.exit(1);
}

baixarComRedundancia();
