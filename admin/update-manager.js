/**
 * update-manager.js
 * Módulo de gerenciamento de atualizações do app Zyrion Play
 * Integra com Firebase Remote Config via REST API
 * 
 * Uso: importar no painel.html e chamar initUpdateManager(db, requireAuth, showToast, setLoading)
 */

// ── Firebase Remote Config REST API ──────────────────────────────────────────
// Usamos a REST API pois o SDK do Remote Config não está disponível no painel
const RC_PROJECT_ID = "streamhub-855ab";
const RC_API_BASE = `https://firebaseremoteconfig.googleapis.com/v1/projects/${RC_PROJECT_ID}/remoteConfig`;

// Chaves do Remote Config usadas pelo app Flutter
const RC_KEYS = {
  LATEST_VERSION: "latest_version",
  APK_URL: "apk_url",
  UPDATE_REQUIRED: "update_required",
  UPDATE_MESSAGE: "update_message",
};

// ── Helpers ───────────────────────────────────────────────────────────────────

function semverCompare(a, b) {
  const pa = String(a || "0.0.0").split(".").map(Number);
  const pb = String(b || "0.0.0").split(".").map(Number);
  for (let i = 0; i < 3; i++) {
    const diff = (pa[i] || 0) - (pb[i] || 0);
    if (diff !== 0) return diff;
  }
  return 0;
}

function escHtml(v) {
  return String(v)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ── Remote Config via Realtime Database (fallback sem auth) ───────────────────
// Armazenamos a config de update no RTDB em /app_config para não precisar
// de OAuth do Remote Config (que requer service account)

const APP_CONFIG_PATH = "app_config";

async function readAppConfig(db, { get, ref }) {
  const snap = await get(ref(db, APP_CONFIG_PATH));
  if (!snap.exists()) return null;
  return snap.val();
}

async function writeAppConfig(db, { set, ref }, config) {
  await set(ref(db, APP_CONFIG_PATH), {
    ...config,
    updatedAt: new Date().toISOString(),
  });
}

// ── UI Builder ────────────────────────────────────────────────────────────────

function buildUpdateSection() {
  return `
    <section id="updateView" class="hidden glass soft-border rounded-3xl p-4 shadow-neon sm:p-6">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <p class="text-xs uppercase tracking-[0.3em] text-violet-300/70">App Updates</p>
          <h2 class="mt-2 text-2xl font-semibold text-white">Gerenciar Atualizações</h2>
          <p class="mt-2 text-sm text-slate-400">
            Configure a versão mais recente do app. O app Flutter verifica automaticamente ao iniciar.
          </p>
        </div>
        <div class="flex items-center gap-3">
          <span id="updateStatusBadge" class="hidden rounded-full border border-violet-400/20 bg-violet-400/10 px-3 py-2 text-xs font-medium text-violet-200">
            Carregando...
          </span>
        </div>
      </div>

      <!-- Current config display -->
      <div id="currentUpdateConfig" class="mt-6 hidden rounded-2xl border border-white/10 bg-white/5 p-4">
        <p class="text-xs uppercase tracking-[0.25em] text-slate-400 mb-3">Configuração Atual</p>
        <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div class="rounded-xl border border-white/8 bg-black/20 p-3">
            <p class="text-xs text-slate-500">Versão publicada</p>
            <p id="curVersion" class="mt-1 text-lg font-semibold text-cyan-300">—</p>
          </div>
          <div class="rounded-xl border border-white/8 bg-black/20 p-3">
            <p class="text-xs text-slate-500">Atualização obrigatória</p>
            <p id="curRequired" class="mt-1 text-lg font-semibold text-white">—</p>
          </div>
          <div class="rounded-xl border border-white/8 bg-black/20 p-3 sm:col-span-2">
            <p class="text-xs text-slate-500">URL do APK</p>
            <p id="curApkUrl" class="mt-1 text-xs text-slate-300 break-all">—</p>
          </div>
        </div>
        <div class="mt-3 rounded-xl border border-white/8 bg-black/20 p-3">
          <p class="text-xs text-slate-500">Mensagem para o usuário</p>
          <p id="curMessage" class="mt-1 text-sm text-slate-300">—</p>
        </div>
        <p class="mt-2 text-xs text-slate-600" id="curUpdatedAt"></p>
      </div>

      <!-- Form -->
      <form id="updateForm" class="mt-6 space-y-5">
        <div class="grid gap-4 lg:grid-cols-2">
          <div>
            <label class="mb-2 block text-sm text-slate-300" for="updateVersion">
              Versão do App
              <span class="ml-1 text-xs text-slate-500">(ex: 1.0.1)</span>
            </label>
            <input
              id="updateVersion"
              type="text"
              autocomplete="off"
              spellcheck="false"
              class="field w-full rounded-2xl px-4 py-3"
              placeholder="1.0.1"
              pattern="\\d+\\.\\d+\\.\\d+"
            />
            <p class="mt-1 text-xs text-slate-500">Formato semver: MAJOR.MINOR.PATCH</p>
          </div>

          <div>
            <label class="mb-2 block text-sm text-slate-300" for="updateRequired">
              Tipo de atualização
            </label>
            <select
              id="updateRequired"
              class="field w-full rounded-2xl px-4 py-3 bg-[rgba(8,9,12,0.86)]"
            >
              <option value="false">Opcional — usuário pode ignorar</option>
              <option value="true">Obrigatória — bloqueia o app</option>
            </select>
          </div>
        </div>

        <div>
          <label class="mb-2 block text-sm text-slate-300" for="updateApkUrl">
            URL do APK
          </label>
          <div class="flex gap-2">
            <input
              id="updateApkUrl"
              type="url"
              autocomplete="off"
              spellcheck="false"
              class="field flex-1 rounded-2xl px-4 py-3 text-sm"
              placeholder="https://github.com/usuario/repo/releases/download/v1.0.1/app-release.apk"
            />
            <button
              type="button"
              id="testApkUrlBtn"
              class="inline-flex items-center gap-2 rounded-2xl border border-cyan-400/20 bg-cyan-400/10 px-4 py-3 text-sm font-medium text-cyan-200 transition hover:bg-cyan-400/20 whitespace-nowrap"
            >
              <i data-lucide="external-link" class="h-4 w-4"></i>
              Testar
            </button>
          </div>
          <p class="mt-1 text-xs text-slate-500">
            Suporta GitHub Releases, Firebase Storage, Cloudflare R2 ou qualquer URL direta para .apk
          </p>
        </div>

        <!-- GitHub helper -->
        <div class="rounded-2xl border border-white/8 bg-black/20 p-4">
          <p class="text-xs uppercase tracking-[0.25em] text-slate-400 mb-3">
            <i data-lucide="github" class="inline h-3.5 w-3.5 mr-1"></i>
            GitHub Releases — Gerador de URL
          </p>
          <div class="grid gap-3 sm:grid-cols-3">
            <div>
              <label class="mb-1 block text-xs text-slate-400">Usuário/Org</label>
              <input id="ghUser" type="text" class="field w-full rounded-xl px-3 py-2 text-sm" placeholder="seu-usuario" />
            </div>
            <div>
              <label class="mb-1 block text-xs text-slate-400">Repositório</label>
              <input id="ghRepo" type="text" class="field w-full rounded-xl px-3 py-2 text-sm" placeholder="zyrion-releases" />
            </div>
            <div>
              <label class="mb-1 block text-xs text-slate-400">Nome do arquivo</label>
              <input id="ghFile" type="text" class="field w-full rounded-xl px-3 py-2 text-sm" placeholder="app-release.apk" />
            </div>
          </div>
          <button
            type="button"
            id="generateGhUrlBtn"
            class="mt-3 inline-flex items-center gap-2 rounded-xl border border-white/10 bg-white/5 px-4 py-2 text-xs font-medium text-slate-200 transition hover:bg-white/10"
          >
            <i data-lucide="link" class="h-3.5 w-3.5"></i>
            Gerar URL e preencher
          </button>
        </div>

        <div>
          <label class="mb-2 block text-sm text-slate-300" for="updateMessage">
            Mensagem para o usuário
          </label>
          <textarea
            id="updateMessage"
            rows="3"
            class="field w-full rounded-2xl px-4 py-3 text-sm resize-none"
            placeholder="Nova versão disponível com melhorias de performance e correções de bugs."
          ></textarea>
        </div>

        <!-- Changelog (optional) -->
        <div>
          <label class="mb-2 block text-sm text-slate-300" for="updateChangelog">
            Changelog
            <span class="ml-1 text-xs text-slate-500">(opcional, exibido no dialog)</span>
          </label>
          <textarea
            id="updateChangelog"
            rows="4"
            class="field w-full rounded-2xl px-4 py-3 text-sm resize-none font-mono"
            placeholder="• Correção de tela preta no player&#10;• Melhoria de latência nas lives&#10;• Novo sistema de perfis"
          ></textarea>
        </div>

        <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
          <button
            id="saveUpdateBtn"
            type="submit"
            class="inline-flex items-center justify-center gap-2 rounded-2xl bg-gradient-to-r from-violet-500 to-fuchsia-500 px-5 py-3 font-semibold text-white shadow-glow transition hover:brightness-110"
          >
            <i data-lucide="upload-cloud" class="h-4 w-4"></i>
            Publicar Atualização
          </button>
          <button
            id="clearUpdateBtn"
            type="button"
            class="inline-flex items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-5 py-3 text-sm font-medium text-slate-200 transition hover:bg-white/10"
          >
            <i data-lucide="refresh-cw" class="h-4 w-4"></i>
            Limpar
          </button>
          <button
            id="disableUpdateBtn"
            type="button"
            class="inline-flex items-center justify-center gap-2 rounded-2xl border border-rose-400/20 bg-rose-400/10 px-5 py-3 text-sm font-medium text-rose-200 transition hover:bg-rose-400/20"
          >
            <i data-lucide="bell-off" class="h-4 w-4"></i>
            Desativar notificação
          </button>
        </div>
      </form>

      <!-- Version history -->
      <div class="mt-8">
        <p class="text-xs uppercase tracking-[0.25em] text-slate-400 mb-3">Histórico de versões</p>
        <div id="versionHistory" class="space-y-2">
          <p class="text-sm text-slate-500">Nenhum histórico disponível.</p>
        </div>
      </div>
    </section>
  `;
}

// ── Nav button for the header ─────────────────────────────────────────────────

function buildUpdateNavButton() {
  return `
    <button
      id="goToUpdateBtn"
      type="button"
      class="hidden inline-flex items-center gap-2 rounded-full border border-violet-400/20 bg-violet-400/10 px-4 py-2 text-sm font-medium text-violet-100 transition hover:border-violet-400/40 hover:bg-violet-400/20"
    >
      <i data-lucide="upload-cloud" class="h-4 w-4"></i>
      Updates
    </button>
  `;
}

// ── Main init function ────────────────────────────────────────────────────────

export function initUpdateManager(db, firebaseOps, { requireAuth, showToast, setLoading, lucide }) {
  const { get, set, ref, push } = firebaseOps;

  // ── Inject HTML ─────────────────────────────────────────────────────────────
  const appView = document.getElementById("appView");
  if (!appView) return;

  // Add nav button to header
  const logoutBtn = document.getElementById("logoutBtn");
  if (logoutBtn) {
    const navBtn = document.createElement("div");
    navBtn.innerHTML = buildUpdateNavButton();
    logoutBtn.parentElement.insertBefore(navBtn.firstElementChild, logoutBtn);
  }

  // Add update section after existing sections
  const updateContainer = document.createElement("div");
  updateContainer.innerHTML = buildUpdateSection();
  appView.appendChild(updateContainer.firstElementChild);

  lucide.createIcons();

  // ── State ───────────────────────────────────────────────────────────────────
  let currentConfig = null;

  // ── Load current config ─────────────────────────────────────────────────────
  async function loadConfig() {
    try {
      currentConfig = await readAppConfig(db, { get, ref });
      renderCurrentConfig(currentConfig);
    } catch (e) {
      console.warn("[UpdateManager] Could not load config:", e);
    }
  }

  function renderCurrentConfig(config) {
    const badge = document.getElementById("updateStatusBadge");
    const section = document.getElementById("currentUpdateConfig");

    if (!config) {
      badge.textContent = "Sem configuração";
      badge.classList.remove("hidden");
      section.classList.add("hidden");
      return;
    }

    section.classList.remove("hidden");
    badge.classList.remove("hidden");

    const version = config[RC_KEYS.LATEST_VERSION] || "—";
    const required = config[RC_KEYS.UPDATE_REQUIRED] === true || config[RC_KEYS.UPDATE_REQUIRED] === "true";
    const apkUrl = config[RC_KEYS.APK_URL] || "—";
    const message = config[RC_KEYS.UPDATE_MESSAGE] || "—";

    document.getElementById("curVersion").textContent = version;
    document.getElementById("curRequired").textContent = required ? "⚠️ Obrigatória" : "✅ Opcional";
    document.getElementById("curApkUrl").textContent = apkUrl;
    document.getElementById("curMessage").textContent = message;

    if (config.updatedAt) {
      document.getElementById("curUpdatedAt").textContent =
        `Última atualização: ${new Date(config.updatedAt).toLocaleString("pt-BR")}`;
    }

    badge.textContent = `v${version} publicada`;

    // Pre-fill form
    document.getElementById("updateVersion").value = version !== "—" ? version : "";
    document.getElementById("updateRequired").value = required ? "true" : "false";
    document.getElementById("updateApkUrl").value = apkUrl !== "—" ? apkUrl : "";
    document.getElementById("updateMessage").value = message !== "—" ? message : "";
    document.getElementById("updateChangelog").value = config.changelog || "";

    // Render history
    renderHistory(config.history || []);
  }

  function renderHistory(history) {
    const container = document.getElementById("versionHistory");
    if (!history.length) {
      container.innerHTML = '<p class="text-sm text-slate-500">Nenhum histórico disponível.</p>';
      return;
    }
    container.innerHTML = history
      .slice()
      .reverse()
      .slice(0, 10)
      .map(
        (entry) => `
        <div class="flex items-center justify-between gap-4 rounded-xl border border-white/8 bg-black/20 px-4 py-3">
          <div class="flex items-center gap-3">
            <span class="rounded-full border border-cyan-400/20 bg-cyan-400/10 px-2 py-0.5 text-xs font-semibold text-cyan-300">
              v${escHtml(entry.version || "?")}
            </span>
            <span class="text-xs text-slate-400">${escHtml(entry.message || "")}</span>
          </div>
          <span class="text-xs text-slate-600 whitespace-nowrap">
            ${entry.publishedAt ? new Date(entry.publishedAt).toLocaleDateString("pt-BR") : ""}
          </span>
        </div>
      `
      )
      .join("");
  }

  // ── Save config ─────────────────────────────────────────────────────────────
  async function saveConfig(event) {
    event.preventDefault();
    if (!requireAuth()) return;

    const version = document.getElementById("updateVersion").value.trim();
    const required = document.getElementById("updateRequired").value === "true";
    const apkUrl = document.getElementById("updateApkUrl").value.trim();
    const message = document.getElementById("updateMessage").value.trim();
    const changelog = document.getElementById("updateChangelog").value.trim();

    // Validate
    if (!version || !/^\d+\.\d+\.\d+$/.test(version)) {
      showToast("Versão inválida. Use o formato MAJOR.MINOR.PATCH (ex: 1.0.1)", "error");
      return;
    }
    if (!apkUrl || !apkUrl.startsWith("http")) {
      showToast("URL do APK inválida.", "error");
      return;
    }
    if (!message) {
      showToast("Informe uma mensagem para o usuário.", "error");
      return;
    }

    setLoading(true, "Publicando atualização", "Salvando configuração no Firebase.");

    try {
      // Build history entry
      const historyEntry = {
        version,
        message,
        changelog,
        apkUrl,
        required,
        publishedAt: new Date().toISOString(),
      };

      const existingHistory = currentConfig?.history || [];
      const newHistory = [...existingHistory, historyEntry].slice(-20); // keep last 20

      const newConfig = {
        [RC_KEYS.LATEST_VERSION]: version,
        [RC_KEYS.APK_URL]: apkUrl,
        [RC_KEYS.UPDATE_REQUIRED]: required,
        [RC_KEYS.UPDATE_MESSAGE]: message,
        changelog,
        history: newHistory,
      };

      await writeAppConfig(db, { set, ref }, newConfig);
      currentConfig = { ...newConfig, updatedAt: new Date().toISOString() };
      renderCurrentConfig(currentConfig);
      showToast(`Versão ${version} publicada com sucesso!`, "success");
    } catch (e) {
      showToast(`Falha ao publicar: ${e.message}`, "error");
    } finally {
      setLoading(false);
    }
  }

  // ── Disable update notification ─────────────────────────────────────────────
  async function disableUpdate() {
    if (!requireAuth()) return;
    if (!confirm("Desativar a notificação de atualização? O app não mostrará mais o dialog.")) return;

    setLoading(true, "Desativando notificação", "");
    try {
      const newConfig = {
        ...(currentConfig || {}),
        [RC_KEYS.LATEST_VERSION]: "0.0.0",
        [RC_KEYS.APK_URL]: "",
        [RC_KEYS.UPDATE_REQUIRED]: false,
        [RC_KEYS.UPDATE_MESSAGE]: "",
      };
      await writeAppConfig(db, { set, ref }, newConfig);
      currentConfig = { ...newConfig, updatedAt: new Date().toISOString() };
      renderCurrentConfig(currentConfig);
      showToast("Notificação de atualização desativada.", "success");
    } catch (e) {
      showToast(`Erro: ${e.message}`, "error");
    } finally {
      setLoading(false);
    }
  }

  // ── GitHub URL generator ────────────────────────────────────────────────────
  function generateGhUrl() {
    const user = document.getElementById("ghUser").value.trim();
    const repo = document.getElementById("ghRepo").value.trim();
    const file = document.getElementById("ghFile").value.trim();
    const version = document.getElementById("updateVersion").value.trim();

    if (!user || !repo || !file) {
      showToast("Preencha usuário, repositório e nome do arquivo.", "error");
      return;
    }

    const tag = version ? `v${version}` : "latest";
    const url = `https://github.com/${user}/${repo}/releases/download/${tag}/${file}`;
    document.getElementById("updateApkUrl").value = url;
    showToast("URL gerada e preenchida!", "success");
  }

  // ── Test APK URL ────────────────────────────────────────────────────────────
  function testApkUrl() {
    const url = document.getElementById("updateApkUrl").value.trim();
    if (!url) {
      showToast("Informe uma URL primeiro.", "error");
      return;
    }
    window.open(url, "_blank", "noopener");
  }

  // ── View switching ──────────────────────────────────────────────────────────
  function showUpdateView() {
    if (!requireAuth()) return;
    document.getElementById("dashboardView")?.classList.add("hidden");
    document.getElementById("manageView")?.classList.add("hidden");
    document.getElementById("updateView")?.classList.remove("hidden");
    document.getElementById("activeViewLabel").textContent = "Updates";
    loadConfig();
    lucide.createIcons();
  }

  function hideUpdateView() {
    document.getElementById("updateView")?.classList.add("hidden");
  }

  // ── Expose hideUpdateView so dashboard/manage can call it ───────────────────
  // Patch existing switchView to also hide update view
  const originalSwitchView = window._switchView;
  if (typeof originalSwitchView === "function") {
    window._switchView = (view) => {
      hideUpdateView();
      originalSwitchView(view);
    };
  }

  // ── Bind events ─────────────────────────────────────────────────────────────
  document.getElementById("goToUpdateBtn")?.addEventListener("click", showUpdateView);
  document.getElementById("updateForm")?.addEventListener("submit", saveConfig);
  document.getElementById("clearUpdateBtn")?.addEventListener("click", () => {
    document.getElementById("updateVersion").value = "";
    document.getElementById("updateApkUrl").value = "";
    document.getElementById("updateMessage").value = "";
    document.getElementById("updateChangelog").value = "";
    document.getElementById("updateRequired").value = "false";
  });
  document.getElementById("disableUpdateBtn")?.addEventListener("click", disableUpdate);
  document.getElementById("generateGhUrlBtn")?.addEventListener("click", generateGhUrl);
  document.getElementById("testApkUrlBtn")?.addEventListener("click", testApkUrl);

  // Show nav button when authenticated
  const observer = new MutationObserver(() => {
    const appView = document.getElementById("appView");
    const btn = document.getElementById("goToUpdateBtn");
    if (!btn) return;
    const isVisible = appView && !appView.classList.contains("hidden");
    btn.classList.toggle("hidden", !isVisible);
  });
  observer.observe(document.getElementById("appView"), { attributes: true, attributeFilter: ["class"] });

  lucide.createIcons();
}
