// bundle.js (Simulação de JavaScript Puro)
window.addEventListener('DOMContentLoaded', () => {
    // 1. Captura o elemento raiz vazio
    const rootElement = document.getElementById('root');

    // 2. Cria a estrutura da página dinamicamente
    const container = document.createElement('div');
    const titulo = document.createElement('h1');
    titulo.textContent = 'Bem-vindo ao Painel do Usuário!';
    
    // 3. Insere os elementos na página
    container.appendChild(titulo);
    rootElement.appendChild(container);
});
