# Sobre - RTD (Pt100 / Pt1000)

Os **RTDs** (*Resistance Temperature Detectors*) são sensores cuja resistência elétrica varia de forma **quase linear** com a temperatura. Os mais comuns são os de **platina**, designados pela resistência nominal a 0 °C: **Pt100** ($R_0 = 100\ \Omega$) e **Pt1000** ($R_0 = 1000\ \Omega$).

Características:

- Excelente **estabilidade** e **repetibilidade**.
- Faixa típica: **-200 °C a +850 °C**.
- Precisão padrão: classes A ($\pm 0{,}15\ ^\circ\text{C}$) e B ($\pm 0{,}30\ ^\circ\text{C}$) a 0 °C (IEC 60751).

---

## 1. Equação de Callendar-Van Dusen

Neste módulo, a forma usada segue a divisão clássica por faixa:

Para **T >= 0 °C**:

$$
R(T) = R_0 \,\big(1 + A\,T + B\,T^{2}\big)
$$

Para **T < 0 °C**:

$$
R(T) = R_0 \,\big(1 + A\,T + B\,T^{2} + C\,(T-100)\,T^{3}\big)
$$

Assim, o termo com `C` só aparece no ramo negativo.

---

## 2. Regra adotada para ajuste dos coeficientes

O programa agora trabalha assim:

1. Se todos os pontos forem **negativos**, ele ajusta **A, B e C**.
2. Se houver temperaturas **mistas** ou apenas **não negativas**, ele ajusta apenas **A e B**.
3. Quando houver pontos mistos e a curva for avaliada em `T < 0 °C`, o programa usa `C` fixo padrão IEC:

$$
C = -4{,}183 \times 10^{-12}
$$

Isso é mostrado também no painel de **coeficientes** por meio de uma nota automática.

---

## 3. Aproximação linear por α

Além da curva de Callendar-Van Dusen, o gráfico também mostra a aproximação:

$$
R(T) = R_0(1+\alpha T)
$$

com:

$$
\alpha = 0{,}0038459\ {\circ\mathrm{C}}^{-1}
$$

Essa segunda curva serve para comparação visual com o modelo mais completo.

---

## 4. Como usar este módulo

1. O módulo inicia com pontos padrão de **Pt100** distribuídos entre **-200 °C** e **850 °C**.
2. Clique em **Calcular**.
3. Veja no painel se o ajuste encontrado foi **A/B** ou **A/B/C**.
4. Compare no gráfico a curva **Callendar-Van Dusen** com a curva **Linear / α**.
5. Use a **calculadora** para conversões $T \leftrightarrow R$.
