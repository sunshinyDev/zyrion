const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Lista de Redundância
const EPG_SOURCES = [
    'https://github.com/limaalef/BrazilTVEPG/raw/main/epg.xml',
    'https://iptv-org.github.io/epg/guides/br.xml',
    'https://github.com/limaalef/BrazilTVEPG/raw/main/claro.xml',
    'https://github.com/limaalef/BrazilTVEPG/raw/main/globo.xml',
    'http://bit.ly/EPG-BR1'
];

// __dirname garante que o arquivo seja salvo na mesma pasta do script (zyrion/epg/)
const OUTPUT_FILE = path.join(__dirname, 'epg_final.xml');

async function baixarComRedundancia() {
    console.log(`\n[${new Date().toISOString()}] Iniciando atualização do EPG...`);
    
    let sucesso = false;

    for (let i = 0; i < EPG_SOURCES.length; i++) {
        const url = EPG_SOURCES[i];
        console.log(`Tentando Fonte ${i + 1}: ${url}`);

        try {
            const response = await axios({
                method: 'get',
                url: url,
                timeout: 20000, // 20 segundos
                responseType: 'stream'
            });

            const writer = fs.createWriteStream(OUTPUT_FILE);
            response.data.pipe(writer);

            await new Promise((resolve, reject) => {
                writer.on('finish', resolve);
                writer.on('error', reject);
            });

            console.log(`✅ Sucesso! Arquivo gerado em: ${OUTPUT_FILE}`);
            sucesso = true;
            break; 

        } catch (error) {
            console.error(`⚠️ Fonte ${i + 1} falhou. Tentando próxima...`);
        }
    }

    if (!sucesso) {
        console.error('❌ ERRO: Todas as fontes falharam.');
        process.exit(1); // Força o GitHub Actions a marcar como erro se nada funcionar
    }
}

baixarComRedundancia();
