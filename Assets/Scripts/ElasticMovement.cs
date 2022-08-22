using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ElasticMovement : MonoBehaviour
{
    public float RangeCoeff = 0.08f;

    public float TimeCoeff = 2.0f;
    
    void Update()
    {
        transform.position = transform.position + (transform.right * Mathf.Cos(Time.time * TimeCoeff) * RangeCoeff);
    }
}
