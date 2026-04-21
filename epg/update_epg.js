const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Lista de Redundância (As melhores fontes BR disponíveis)
const EPG_SOURCES = [
    'https://github.com/limaalef/BrazilTVEPG/raw/main/epg.xml',
    'https://iptv-org.github.io/epg/guides/br.xml',
    'https://github.com/limaalef/BrazilTVEPG/raw/main/claro.xml',
    'https://github.com/limaalef/BrazilTVEPG/raw/main/globo.xml',
    'http://bit.ly/EPG-BR1'
];

// Garante que o arquivo será salvo na mesma pasta do script (zyrion/epg/)
const OUTPUT_FILE = path.join(__dirname, 'epg_final.xml');

async function baixarComRedundancia() {
    console.log(`\n[${new Date().toISOString()}] Iniciando ZyrionPlay EPG Engine...`);
    
    let sucesso = false;

    for (let i = 0; i < EPG_SOURCES.length; i++) {
        const url = EPG_SOURCES[i];
        console.log(`\nTentando Fonte ${i + 1}: ${url}`);

        try {
            const response = await axios({
                method: 'get',
                url: url,
                timeout: 30000, // Aumentado para 30 segundos de limite
                responseType: 'stream'
            });

            const writer = fs.createWriteStream(OUTPUT_FILE);
            response.data.pipe(writer);

            // Aguarda o arquivo ser totalmente salvo no disco
            await new Promise((resolve, reject) => {
                writer.on('finish', resolve);
                writer.on('error', reject);
            });

            console.log(`✅ Sucesso! EPG baixado e salvo em: ${OUTPUT_FILE}`);
            sucesso = true;
            break; // Sai do loop assim que conseguir baixar de uma fonte

        } catch (error) {
            // MOSTRAMOS O ERRO EXATO PARA SABER POR QUE FALHOU (Ex: 404, Timeout)
            console.error(`⚠️ Fonte ${i + 1} falhou!`);
            console.error(`   -> Motivo: ${error.message}`);
        }
    }

    // Se passou pelas 5 fontes e não conseguiu, mata o processo com erro 1 pro GitHub
    if (!sucesso) {
        console.error('\n❌ ERRO CRÍTICO: Todas as fontes de EPG falharam.');
        process.exit(1); 
    }
}

// Inicia o processo
baixarComRedundancia();
