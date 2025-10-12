# 📸 Captures d'écran - Application Exemple

Documentation visuelle de l'application exemple **Capture Helper**.

## 🏠 Page d'accueil

### État initial
```
┌─────────────────────────────────┐
│  Capture Helper Example    ⚙️   │
├─────────────────────────────────┤
│                                 │
│         📄                      │
│    Document Scanner             │
│                                 │
│  Scan documents using your      │
│  device camera                  │
│                                 │
│    ┌───────────────────┐        │
│    │  📷 Scan Document │        │
│    └───────────────────┘        │
│                                 │
│  ℹ️ Scanner disponible          │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Features                │   │
│  │ ✓ Automatic edge detection│
│  │ ✓ Multi-page scanning   │   │
│  │ ✓ Image compression     │   │
│  │ ✓ High-quality output   │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Éléments clés** :
- Icône document scanner (grise si indisponible, bleue si disponible)
- Bouton "Scan Document" (désactivé si scanner indisponible)
- Message de statut
- Card avec liste des fonctionnalités

### Pendant le scan
```
┌─────────────────────────────────┐
│  Capture Helper Example    ⚙️   │
├─────────────────────────────────┤
│                                 │
│         📄                      │
│    Document Scanner             │
│                                 │
│         ⏳ Loading...           │
│                                 │
│  ℹ️ Opening scanner...          │
│                                 │
└─────────────────────────────────┘
```

### Après un scan réussi
```
┌─────────────────────────────────┐
│  Capture Helper Example    ⚙️   │
├─────────────────────────────────┤
│                                 │
│    ┌───────────────────┐        │
│    │  📷 Scan Document │        │
│    └───────────────────┘        │
│                                 │
│  ℹ️ Successfully scanned 2      │
│     image(s)                    │
│                                 │
│  → Navigation automatique vers  │
│     la page de détails          │
└─────────────────────────────────┘
```

---

## 📄 Page de détails

### Vue d'une seule page
```
┌─────────────────────────────────┐
│ ← Scan Details (1/1)            │
├─────────────────────────────────┤
│  ╔═══════════════════════════╗  │
│  ║                           ║  │
│  ║      [Image Preview]      ║  │
│  ║                           ║  │
│  ║                           ║  │
│  ╚═══════════════════════════╝  │
│                                 │
│  Original Image                 │
│  Size: 1.2 MB                   │
│  Path: scan_1234567890_0.jpg    │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Image Compression              │
│                                 │
│  Quality: ├────●────┤ 80%       │
│  Good quality - Balanced        │
│                                 │
│  ┌─────────────────────────┐   │
│  │  🗜️ Compress Image      │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**Éléments clés** :
- Aperçu de l'image en haut (400px de hauteur)
- Informations du fichier (taille, nom)
- Slider de qualité avec indicateur (10-100%)
- Description dynamique de la qualité
- Bouton de compression

### Vue multi-pages (navigation)
```
┌─────────────────────────────────┐
│ ← Scan Details (2/3)  ◀️  ▶️    │
├─────────────────────────────────┤
│  ╔═══════════════════════════╗  │
│  ║   [Image Preview Page 2]  ║  │
│  ╚═══════════════════════════╝  │
│                                 │
│  [Informations et compression]  │
└─────────────────────────────────┘
```

**Fonctionnalités de navigation** :
- Compteur de pages dans le titre (2/3)
- Boutons fléchés ◀️ ▶️ pour naviguer
- Boutons désactivés aux extrémités

### Pendant la compression
```
┌─────────────────────────────────┐
│  Image Compression              │
│                                 │
│  Quality: ├────●────┤ 80%       │
│                                 │
│  ┌─────────────────────────┐   │
│  │  ⏳ Compressing...      │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

### Résultat de compression
```
┌─────────────────────────────────┐
│  ┌─────────────────────────┐   │
│  │ ✅ Compression Successful │  │
│  ├─────────────────────────┤   │
│  │ Original Size    1.2 MB │   │
│  │ Compressed Size  456 KB │   │
│  │ Space Saved      788 KB │   │
│  │ Reduction         62.0% │   │
│  ├─────────────────────────┤   │
│  │ Output: compressed_...  │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

**Card verte avec** :
- Icône ✅ et titre
- Tableau des statistiques
- Nom du fichier de sortie

---

## 📊 Exemples de slider de qualité

### Qualité haute (90%)
```
Quality: ├─────────●─┤ 90%
High quality - Minimal compression, larger file size
```

### Qualité moyenne (70%)
```
Quality: ├──────●───┤ 70%
Good quality - Balanced compression and quality
```

### Qualité basse (40%)
```
Quality: ├──●───────┤ 40%
Low quality - Maximum compression, smallest file size
```

---

## 🎨 Palette de couleurs

### Couleurs principales
- **Primary** : Blue (Theme.colorScheme.primary)
- **Success** : Green[50] / Green[700]
- **Warning** : Orange
- **Error** : Red
- **Background** : Grey[100] / Grey[200]

### États des boutons
- **Actif** : Bleu avec ombre
- **Chargement** : CircularProgressIndicator
- **Désactivé** : Gris

---

## 📱 Messages utilisateur

### SnackBars

**Succès (vert)** :
```
┌─────────────────────────────────┐
│ 2 image(s) scannée(s)      ✕   │
└─────────────────────────────────┘
```

```
┌─────────────────────────────────┐
│ Compressé : 62.0% de réduction ✕│
└─────────────────────────────────┘
```

**Erreur (rouge)** :
```
┌─────────────────────────────────┐
│ Erreur : Scanner non disponible ✕│
└─────────────────────────────────┘
```

**Info (bleue)** :
```
┌─────────────────────────────────┐
│ Scan annulé                   ✕ │
└─────────────────────────────────┘
```

---

## 🎬 Flux utilisateur complet

```
┌──────────────┐
│ Page d'accueil│
│              │
│ [Scan Doc]  │ ← Clic utilisateur
└──────┬───────┘
       │
       ↓
┌──────────────┐
│ Scanner natif│ ← Interface VisionKit/ML Kit
│ (iOS/Android)│
└──────┬───────┘
       │
       ↓ (Scan réussi)
┌──────────────┐
│ Page détails │
│              │
│ Image 1/2    │
│              │
│ [Quality: 80]│ ← Ajustement slider
│              │
│ [Compress]   │ ← Clic utilisateur
└──────┬───────┘
       │
       ↓
┌──────────────┐
│ Compression  │
│ en cours...  │
└──────┬───────┘
       │
       ↓
┌──────────────┐
│ Résultat     │
│ ✅ Card verte│
│ Statistiques │
└──────────────┘
```

---

## 💡 Notes de design

### Espacement
- Padding général : 16-24px
- Espacement entre sections : 32px
- Espacement entre éléments : 8-16px

### Typographie
- Titre : headlineMedium
- Sous-titre : titleLarge
- Corps : bodyLarge
- Info : caption (12px)

### Coins arrondis
- Cards : 8px
- Boutons : Suivre le thème Material 3
- Images : Pas de coins arrondis (fit: BoxFit.contain)

### Animations
- Bouton chargement : CircularProgressIndicator (20x20px)
- SnackBar : Slide from bottom
- Navigation : Push/Pop standard

---

## 📐 Dimensions

### Page d'accueil
- Icône : 100x100px
- Bouton : horizontal: 32px, vertical: 16px
- Card Features : full width - 32px padding

### Page de détails
- Preview image : height: 400px, width: double.infinity
- Slider : full width avec padding
- Badge qualité : padding: 12x6px

---

## 🎯 Points d'attention UX

1. **Feedback immédiat** : Loading states visibles
2. **Messages clairs** : SnackBars avec icônes
3. **Désactivation contextuelle** : Boutons grisés quand non disponibles
4. **Navigation intuitive** : Flèches pour multi-pages
5. **Statistiques lisibles** : Format humain (MB, KB au lieu de bytes)
6. **Guidage utilisateur** : Descriptions de qualité dynamiques

---

Pour voir l'application en action, lancez :
```bash
cd example
flutter run
```
