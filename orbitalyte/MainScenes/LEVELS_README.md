# Orbitalyte Levels - Template System

## Estructura

`LevelTemplate.tscn` contiene todos los elementos comunes a cualquier nivel:
- **Parallax2D** - Fondo con capas parallax
- **GameContainer** - Contenedor principal del juego
  - **PlanetsContainer** - Contiene StartPlanet, GoalPlanet y BlockerPlanets
    - **BlockerPlanetExample** - Planeta bloqueador de ejemplo (puedes duplicarlo)
  - **ShipVisuals** - Nave, trail y preview de lanzamiento
- **UIPanel** - Botones de control y barra de energía
- **GameManager** - Gestor del juego
- **InputManager** - Gestor de entrada

## Crear un Nuevo Nivel

### Opción 1: Duplicar LevelTemplate (Recomendado)
1. En tu proyecto, ve a `MainScenes` 
2. Duplica `LevelTemplate.tscn` y renómbralo `Level3.tscn`
3. Abre `Level3.tscn`
4. En el editor, expande `Main > GameContainer > PlanetsContainer`
5. **BlockerPlanetExample** ya está ahí - puedes:
   - **Duplicarlo** (Ctrl+D): Crea otro planeta bloqueador con las mismas propiedades
   - **Eliminarlo** (Delete): Si no necesitas tantos planetas
   - **Modificarlo**: Cambia posición, tamaño, sprite, color, etc.

### Opción 2: Crear desde Cero
1. Crea una nueva escena `Level3.tscn` 
2. Instancia `LevelTemplate.tscn` en el root
3. Automáticamente tendrás `BlockerPlanetExample` para trabajar

## Personalizar BlockerPlanets

En el Inspector, puedes cambiar:
- **Position** - Dónde está el planeta
- **Radius** - Tamaño del planeta (afecta colisión y atracción)
- **Gravity** - Fuerza de atracción gravitatoria
- **Orbital_Multiplier** - Modificador de órbita
- **Sprite_Texture** - Imagen del planeta
- **Tint_Color** - Color del tinte

## ¿Descartar BlockerPlanetExample?

Si creas un nivel vacío sin planetas bloqueadores:
1. En PlanetsContainer, elimina `BlockerPlanetExample`
2. Solo quedaran StartPlanet y GoalPlanet

## Script de Configuración

Los niveles se cargan automáticamente desde el `LevelManager`:
- Level 1: `res://MainScenes/Level1.tscn`
- Level 2: `res://MainScenes/Level2.tscn`
- Level 3: `res://MainScenes/Level3.tscn`

Cuando termines un nivel, el juego automáticamente carga el siguiente.

