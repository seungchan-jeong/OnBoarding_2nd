using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ComputeShaderDispatcher : MonoBehaviour
{
    public ComputeShader computeShader;
    public RawImage rawImage;

    private RenderTexture renderTexture;

    private void Update()
    {
        RunComputeShader();
    }

    public void RunComputeShader()
    {
        const int rtWidth = 512;
        const int rtHeight = 512;
        
        if (renderTexture == null)
        {
            renderTexture = new RenderTexture(rtWidth, rtHeight, 1, RenderTextureFormat.ARGB32);
            renderTexture.enableRandomWrite = true;
            renderTexture.Create();

            if (rawImage != null)
            {
                rawImage.texture = renderTexture;
            }
  
        }

        int kernelHandle = computeShader.FindKernel("CSMain");
        computeShader.GetKernelThreadGroupSizes(kernelHandle, out uint kernelX, out uint kernelY, out uint kernelZ);
        computeShader.SetTexture(kernelHandle, "Result", renderTexture);
        computeShader.SetVector("_Time", Shader.GetGlobalVector("_Time"));
        computeShader.SetVector("_Resolution", new Vector2(rtWidth, rtHeight));
        computeShader.Dispatch(kernelHandle, rtWidth / (int)kernelX , rtHeight/ (int)kernelY, 1);
        // computeShader.Dispatch(kernelHandle, rtWidth / 8 , rtHeight/ 8, 1);

    }
}
