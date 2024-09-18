using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostProcessing : MonoBehaviour
{
    
    public Shader PostProcessingShader;
    [Range(0f, 1f)] public float Value;
    private Material m_Material;
    public Material Material
    {
        get 
        {
            if (PostProcessingShader == null)
            {
                Debug.LogError("未指定Shader！");
                return null;                   
            }
            if (!PostProcessingShader.isSupported)
            {
                Debug.LogError("不支持的Shader！");
                return null;
            }
            if (m_Material == null)
            {
                Material newMaterail = new Material(PostProcessingShader);
                newMaterail.hideFlags = HideFlags.HideAndDontSave;
                m_Material = newMaterail;
                return newMaterail;
            }
            else
            {
                return m_Material;
            }
            
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Material.SetFloat("_Value", Value);
        Graphics.Blit(source, destination, Material);
        //Debug.Log(Material.GetFloat("_Value"));
    }


}
