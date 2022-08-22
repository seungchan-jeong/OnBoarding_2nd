using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class CustomLit : ShaderGUI
{
    private readonly string Diffuse = "_Diffuse";
    private readonly string Specular = "_Specular";
    private readonly string Ambient = "_Ambient";
    
    public override void ValidateMaterial(Material material)
    {
        if (material.HasProperty(Diffuse))
            CoreUtils.SetKeyword(material, Diffuse, material.GetFloat(Diffuse) == 1.0f);
        if (material.HasProperty(Specular))
            CoreUtils.SetKeyword(material, Specular, material.GetFloat(Specular) == 1.0f);
        if (material.HasProperty(Ambient))
            CoreUtils.SetKeyword(material, Ambient, material.GetFloat(Ambient) == 1.0f);
    }
}
