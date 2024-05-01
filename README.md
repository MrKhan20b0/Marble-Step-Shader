# Marble Step Shader
A ghostly / sylized statue shader insipred by the works of  Kazuki Takamatsu


![Alt text](ScreenShots/PoseMat_front.png?raw=true "GhostMat")
![Alt text](ScreenShots/PoseMat_back.png?raw=true "GhostMat")
![Alt text](ScreenShots/GhostMat_back.png?raw=true "GhostMat")
![Alt text](ScreenShots/GhostMat_front.png?raw=true "GhostMat")

## Installation
You may clone this repo into your Unity project, or import the unity package provided in [releases](https://github.com/MrKhan20b0/Marble-Step-Shader/releases)

## Shader Params

### Contrast
Controls contrast between **ColorLight** and **ColorDark** portions of whats shaded.

### Offset
Shifts where **ColorLight** and **ColorDark** begin and end on the material.

### Max Depth & Min Depth
Functions similarly to **Contrast** and **Offset**, but gives find tune adjustment.
Can be used to invert the gradient if MinDepth > MaxDepth.

### Clamp Depth
If on; will force colors on material to be between **ColorLight** and **ColorDark**.
If off; possible for dark or white colors to exist depending on **Contrast** and **Offset**.

### Steps
Determins how many "Slices" appear on the material.
A high value will appear to be smooth.
![Alt text](ScreenShots/PoseMat_HighSteps.png?raw=true "Low Steps")
A low value will appear to have low color-bit-depth
![Alt text](ScreenShots/PoseMat_LowSteps.png?raw=true "Low Steps")
A medium value, 44 in this example (depnds on size of model)
![Alt text](ScreenShots/PoseMat_MediumSteps(44).png?raw=true "Low Steps")

### Color Light & Color Dark
Surfaces closer to the camera will be more **ColorLight** while surfaces further away will be more **ColorDark**

### Shadow Color
Determines the color of the shadow between layers. See **Layer Shadow Ammount**
This color is additive to **ColorLight** and **ColorDark**.

### Layer Shadow Ammount
Noticable when **Steps** is low.
Creats a "Shadow" effect between layers created by the **steps** paramater.
With **Layer Shadow Ammount** set to 0:
![Alt text](ScreenShots/noShadow.png?raw=true "No Shadow")
With **Layer Shadow Ammount** set to 1:
![Alt text](ScreenShots/Shadow.png?raw=true "Shadow")

### Layer Shadow Noise
Determines the chance for a pixel in a layer shadow to be rendered normally, as in Layer Shadow Ammount is 0.
A value of 0.5 equates to half of pixels in shadow being rendred normally.
A value of 1.0 equates to all pixels in shadow being rendred normally.

With **Layer Shadow Noise** set to 0.5:
![Alt text](ScreenShots/ShadowNoise.png?raw=true "Noise")

### Debug Colors
Requires code to be uncommented in shader.
Shows colors representing the depth from the camera to surface of model with this shader.
Useful to visualize how **Contrast**, **Offset**, **MinDepth**, and **MaxDepth** affects the output.
![Alt text](ScreenShots/debug.png?raw=true "debug")

## License
MIT