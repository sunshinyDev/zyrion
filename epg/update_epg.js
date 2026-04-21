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

// Isso garante que o XML seja salvo dentro de zyrion/epg/
const OUTPUT_FILE = path.join(__dirname, 'epg_final.xml');

async function baixarComRedundancia() {
    console.log(`[${new Date().toISOString()}] Iniciando busca de EPG...`);
    let sucesso = false;

    for (let i = 0; i < EPG_SOURCES.length; i++) {
        const url = EPG_SOURCES[i];
        console.log(`Tentando Fonte ${i + 1}: ${url}`);

        try {
            const response = await axios({
                method: 'get',
                url: url,
                timeout: 25000,
                responseType: 'stream'
            });

            const writer = fs.createWriteStream(OUTPUT_FILE);
            response.data.pipe(writer);

            await new Promise((resolve, reject) => {
                writer.on('finish', resolve);
                writer.on('error', reject);
            });

            console.log(`✅ Sucesso! Arquivo salvo em: ${OUTPUT_FILE}`);
            sucesso = true;
            break; 
        } catch (error) {
            console.error(`⚠️ Fonte ${i + 1} falhou.`);
        }
    }

    if (!sucesso) {
        console.error('❌ Todas as fontes falharam.');
        process.exit(1); 
    }
}

baixarComRedundancia();
