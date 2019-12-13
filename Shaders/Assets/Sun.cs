using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Sun : MonoBehaviour
{
    public bool enabledd;
    public float rotateSpeed;
    public Vector3 rotateAmount;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (enabledd)
        {
            transform.Rotate(rotateAmount * rotateSpeed * Time.deltaTime);
        }
    }
}
