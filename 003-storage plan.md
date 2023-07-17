## 1. Kubernetes 常见存储解决方案性能对比

https://medium.com/volterra-io/kubernetes-storage-performance-comparison-v2-2020-updated-1c0b69f0dcf4

译：https://zhuanlan.zhihu.com/p/337076325

- Azure pvc
- Azure hostPath
- Portworx
- GlusterFS
- Ceph
- OpenEBS
- Longhorn

### 1.1  结论

在选择存储解决方案时，请仅将结果作为标准之一，不要仅根据本文的数据做出最终判断。

- Portworx和OpenEBS是AKS最快的容器存储。
- ceph在节点数不多的情况下表现较差
- 围绕NVMe的稳健设计，OpenEBS似乎已成为最好的开源容器存储选项之一。
- 对于简单的块存储用例，Longhorn绝对是有效的选择，它与OpenEBS Jiva后端非常相似。

当然，这只是评估容器存储的一种方法。其他需要关注的部分还包括弹性和稳定性。

### 1.2 性能测试 

- 随机读写带宽

  - 随机读BW：Portworx > GlusterFS >  Ceph 1.3x> OpenEBS > Longhorn  > Azure hostPath >  Azure pvc
  - 随机写BW:  Ceph 2x> OpenEBS 

  - OpenEBS和Longhorn的性能几乎是本地磁盘的**两倍**。原因是读取了**缓存**

- 随机读写IOPS

  ![v2-1d06eb73af03ca3ca1569f2e31ca1946_720w](D:\IFLYTEK\DevOps\photo\v2-1d06eb73af03ca3ca1569f2e31ca1946_720w.webp)

  - 随机读IOPS：Portworx 3x > OpenEBS = Ceph 2x> Longhorn
  - 随机写IOPS:   OpenEBS 2.3x > Portworx > Ceph 

- 读写延迟

  ![1_oCWK2dtjGhBBGRSWjeTZ1A](D:\IFLYTEK\DevOps\photo\1_oCWK2dtjGhBBGRSWjeTZ1A.webp)

  - OpenEBS和Longhorn上写入的延迟更好。 GlusterFS仍然比其他存储更好。

- 顺序读/写

  ![1_gSHVkB1nGIPOAZVOb-xDgw](D:\IFLYTEK\DevOps\photo\1_gSHVkB1nGIPOAZVOb-xDgw.webp)

  - 顺序读/写测试显示的结果与随机测试相似
  - 顺序读：Longhorn ≈ OpenEBS ≈ Ceph
  - 顺序写：Longhorn   ≈ OpenEBS 1.5x> Ceph 

- 混合读/写IOPS

  ![1_8douej2u6YASr46UyqL1ug](D:\IFLYTEK\DevOps\photo\1_8douej2u6YASr46UyqL1ug.webp)

  - 在读写方面，OpenEBS交付的速度几乎是PortWorx或Longhorn的两倍。
  - 混合读写 ：OpenEBS 2x> Ceph = Longhorn 







