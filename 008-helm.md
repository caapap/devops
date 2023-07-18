# 前言

​		Helm使用一种称为chart的打包格式。图表是描述一组相关Kubernetes资源的文件集合。单个chart可以用于部署简单的东西，如memcached pod，也可以用于部署复杂的东西，如包含HTTP服务器、数据库、缓存等的完整web应用程序堆栈。

​		chart是以文件的形式创建的，放在特定的目录树中，然后可以将它们打包到版本化的归档中进行部署。

​		本文档解释了chart格式，并提供了使用Helm构建chart的基本指导。

# chart介绍

## 1. chart文件结构

chart被组织为目录中的文件集合。目录名称是chart的名称（没有版本信息）。因此，描述WordPress的chart将存储在`wordpress/` 目录中。

在这个目录中，Helm将期望一个与此匹配的结构：

```shell
wordpress/
  Chart.yaml          # A YAML file containing information about the chart
  LICENSE             # OPTIONAL: A plain text file containing the license for the chart
  README.md           # OPTIONAL: A human-readable README file
  requirements.yaml   # OPTIONAL: A YAML file listing dependencies for the chart
  values.yaml         # The default configuration values for this chart
  charts/             # A directory containing any charts upon which this chart depends.
  templates/          # A directory of templates that, when combined with values,
                      # will generate valid Kubernetes manifest files.
  templates/NOTES.txt # OPTIONAL: A plain text file containing short usage notes
```

Helm保留使用 `charts/` 和 `templates/`目录和列表中文件名称。其他文件将保持原样。

## 2. Chart.yaml文件

chart需要一个`Chart.yaml` 。它包含以下字段:

```shell
apiVersion: The chart API version, always "v1" (required)
name: The name of the chart (required)
version: A SemVer 2 version (required)
kubeVersion: A SemVer range of compatible Kubernetes versions (optional)
description: A single-sentence description of this project (optional)
keywords:
  - A list of keywords about this project (optional)
home: The URL of this project's home page (optional)
sources:
  - A list of URLs to source code for this project (optional)
maintainers: # (optional)
  - name: The maintainer's name (required for each maintainer)
    email: The maintainer's email (optional for each maintainer)
    url: A URL for the maintainer (optional for each maintainer)
engine: gotpl # The name of the template engine (optional, defaults to gotpl)
icon: A URL to an SVG or PNG image to be used as an icon (optional).
appVersion: The version of the app that this contains (optional). This needn't be SemVer.
deprecated: Whether this chart is deprecated (optional, boolean)
tillerVersion: The version of Tiller that this chart requires. This should be expressed as a SemVer range: ">2.0.0" (optional)

```

如果你熟悉Helm Classic的`Chart.yaml`文件的格式，你将注意到指定依赖项的字段已被删除。这是因为新的chart格式使用`charts/` 目录表示依赖关系。

其他字段将被忽略。

### 2.1 chart和版本

每个chart必须有一个版本号。一个版本必须遵循[SemVer 2](https://semver.org/)标准。与Helm Classic不同，Kubernetes Helm使用版本号作为发布标志。仓库中的包由名称和版本标识。

例如，将一个`nginx` chart的`version`字段设置为`version: 1.2.3`将被命名为：

```shell
nginx-1.2.3.tgz
```

还支持更复杂的SemVer 2名称，比如 `version: 1.2.3-alpha.1+ef365`。但是系统显式地禁止非SemVer名称。

<table><tr><td bgcolor=lightblue>注意：虽然Helm Classic和部署管理器在chart方面都非常面向GitHub，但是Kubernetes Helm并不依赖或需要GitHub，甚至Git。因此，它根本不使用Git SHA进行版本控制。</td></tr></table>

`Chart.yaml`中的`version`字段被许多Helm工具使用，包括CLI和Tiller服务商。在生成包时，`helm package`命令将使用它在 `Chart.yaml`中找到的版本作为包名称中的标记（token）。系统假设chart包名称中的版本号与图`Chart.yaml`中的版本号匹配。不符合这一假设将会导致错误。

### 2.2 appVersion字段

注意，`appVersion`字段与`version`字段不相关。它是一种指定应用程序版本的方法。例如，`drupal` chart可能有一个`appVersion: 8.2.1`，这表示chart中包含的`drupal版本`（默认情况下）是8.2.1。此字段是信息性的，对chart版本计算没有影响

### 2.3 废弃chart

在chart仓库中管理chart时，有时需要废弃chart。`Chart.yaml`中可选的`deprecated` 字段可用于将chart标记为已废弃。如果仓库中chart的最新版本被标记为已废弃，则认为整个chart已弃用。随后可以通过发布未标记为已弃用的新版本来重用chart名称。废弃chart的工作流程如下：

- 更新chart的 `Chart.yaml`文件，将chart标记为已废弃，碰撞版本
- 在chart仓库中发布新的chart版本
- 从源代码仓库中删除chart（例如git）

## 3. chart许可证、README和说明

chart还可以包含描述chart的安装、配置、使用和许可证的文件。

许可证是包含chart[许可证](https://en.wikipedia.org/wiki/Software_license)的纯文本文件。chart可以包含一个许可证，因为它可能在模板中有编程逻辑，因此不只是配置。如果需要，还可以为chart安装的应用程序提供单独的许可证。

图表的自述应该是Markdown （README.md）格式的，并且通常应该包含：

- chart提供的应用程序或服务的描述
- 运行chart的任何前提条件或要求
- `values.yaml`文件中选项的描述和默认值
- 与chart的安装或配置相关的任何其他信息

chart还可以包含一个简短的纯文本 `templates/NOTES.txt`文件，该文件将在安装之后以及查看发布状态时打印出来。此文件作为[模板](https://helm.sh/docs/developing_charts/#templates-and-values)进行计算，可用于显示使用说明、下一步操作或与chart发布相关的任何其他信息。例如，可以提供连接数据库或访问web UI的指令。由于该文件在运行`helm install`或`helm status`时被打印为标准输出，因此建议保持内容简短，并指向README以获得更详细的信息。

## 4. chart依赖

在Helm中，一个chart可以依赖于任意数量的其他图表。这些依赖关系可以通过 `requirements.yaml`文件动态链接或导入到 `charts/`目录并手动管理。

尽管手动管理依赖项有一些团队需要，但优点很少，使用chart中的一个 `requirements.yaml`文件是首选方式。

<table><tr><td bgcolor=lightblue>注意：来自Helm Classic的Chart.yaml的dependencies: 部分已经被完全移除。</td></tr></table>

### 4.1 使用requirements.yaml管理依赖

一个`requirements.yaml`文件是一个列出依赖项的简单文件。

```shell
dependencies:
  - name: apache
    version: 1.2.3
    repository: http://example.com/charts
  - name: mysql
    version: 3.2.1
    repository: http://another.example.com/charts

```

- `name`字段是你想要的chart的名称。
- `version`字段是你想要的chart的版本。
- `repository`字段是chart仓库的完整URL。请注意，你还必须使用`helm repo add`命令在本地添加该仓库。

一旦你有了一个依赖文件，你可以运行 `helm dependency update`，它会使用你的依赖文件为你下载所有指定的chart到你的`charts/`目录中。

```shell
$ helm dep up foochart
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "local" chart repository
...Successfully got an update from the "stable" chart repository
...Successfully got an update from the "example" chart repository
...Successfully got an update from the "another" chart repository
Update Complete.
Saving 2 charts
Downloading apache from repo http://example.com/charts
Downloading mysql from repo http://another.example.com/charts

```

当`helm dependency update`检索chart时，它将把它们作为chart归档文件存储在`charts/`目录中。因此，对于上面的示例，可以在`charts/`目录中看到以下文件：

```shell
charts/
  apache-1.2.3.tgz
  mysql-3.2.1.tgz
```

使用 `requirements.yaml`管理chart是一种很好的方法，可以轻松地更新chart，并在整个团队中共享需求信息。

### 4.2 requirements.yaml中的alias字段

除了上面的其他字段之外，每个需求条目可能包含可选的`alias`字段。

为依赖chart添加`alias`会将chart放入依赖项中，并使用别名作为新依赖项的名称。

在需要访问具有其他名称的chart时，可以使用`alias`。

```shell
# parentchart/requirements.yaml
dependencies:
  - name: subchart
    repository: http://localhost:10191
    version: 0.1.0
    alias: new-subchart-1
  - name: subchart
    repository: http://localhost:10191
    version: 0.1.0
    alias: new-subchart-2
  - name: subchart
    repository: http://localhost:10191
    version: 0.1.0
```

在上面的例子中，我们为 `parentchart`将得到3个依赖放在一起：

```shell
subchart
new-subchart-1
new-subchart-2
```

实现此目的的手动方法是使用不同的名称在`charts/`目录中多次复制/粘贴相同的chart。

### 4.3 requirements.yaml中的tags和condition字段

除了上面的其他字段外，每个需求条目可能包含可选字段`tags`和`condition`。

所有chart都是默认加载的。如果存在`tags`或`condition`字段，则将对它们进行计算，并使用它们来控制所应用的chart的加载。

条件：`condition`字段包含一个或多个YAML路径（由逗号分隔）。如果此路径存在于父chart的值中并解析为布尔值，则将根据该布尔值启用或禁用chart。只计算列表中找到的第一个有效路径，如果没有路径存在，则条件无效。对于多级依赖项，该条件由到父chart的路径预先确定。

标签：`tags`字段是与此图表相关联的标签的YAML列表。在顶层的父chart值中，通过指定标签和布尔值，可以启用或禁用所有带有标答的chart。

```shell
# parentchart/requirements.yaml
dependencies:
  - name: subchart1
    repository: http://localhost:10191
    version: 0.1.0
    condition: subchart1.enabled
    tags:
      - front-end
      - subchart1

  - name: subchart2
    repository: http://localhost:10191
    version: 0.1.0
    condition: subchart2.enabled
    tags:
      - back-end
      - subchart2

```

```shell
# subchart2/requirements.yaml
dependencies:
  - name: subsubchart
    repository: http://localhost:10191
    version: 0.1.0
    condition: subsubchart.enabled
```

```shell
# parentchart/values.yaml

subchart1:
  enabled: true
subchart2:
  subsubchart:
    enabled: false
tags:
  front-end: false
  back-end: true
```

在上面的例子中，所有带有`front-end`标签的chart都将被禁用，但由于在父chart的值中`subchart1.enabled` 路径的值为true，条件将覆盖 `front-end`标签，所以`subchart1`将被启用。

由于`subchart2`拥有`back-end` 标签，并且该标签的计算结果为true，因此`subchart2`将被启用。还要注意，尽管`subchart2`有一个在`requirements.yaml`中指定的条件，但在父chart的值中没有对应的路径和值，所以该条件不起作用。

`subsubchart`在默认情况下是禁用的，但是可以通过设置`subchart2.subsubchart.enabled=true`来启用。提示：通过标签禁用`subchart2`也将禁用其所有子chart（即使覆盖了`subchart2.subsubchart.enabled=true`值）。

```shell
helm install --set tags.front-end=true --set subchart2.enabled=false
```

##### 

#### 4.3.1CLI中使用标签和条件

可以像往常一样使用`--set`参数来更改标签和条件值。

```shell
helm install --set tags.front-end=true --set subchart2.enabled=false
```

#### 4.3.2 标签和条件解析

- 条件（在值（values）中设置时）总是覆盖标签。
- 存在的第一个条件路径将获胜，该chart的后续条件路径将被忽略。
- 标签被计算为“如果chart的所有标签值为true，那么启用该chart”。
- 标签和条件值必须在顶层父元素的值（values）中设置。
- 值（values）中的`tags:`键必须是顶层键。当前不支持全局和嵌套的 `tags:`。

### 4.4 通过requirements.yaml导入子值（values）

在某些情况下，希望允许子chart的值传播到父chart，并作为公共缺省值共享。使用 `exports`格式的另一个好处是，它将使未来的工具能够内省用户可设置的值。

包含要导入的值的键可以使用一个YAML列表在父chart的`requirements.yaml` 文件中指定。列表中的每个项都是从子chart的`exports`字段导入的键。

若要导入 `exports`键中不包含的值，请使用[子-父格式](https://www.coderdocument.com/docs/helm/v2/charts/intro_to_charts.html#shiyongzi-fugeshi)。下面将介绍这两种格式的示例。

#### 4.4.1 使用导出格式

如果一个子chart的`values.yaml`文件在根中包含一个`exports`字段，它的内容可以通过指定要导入的键直接导入到父chart的值中，如下例所示：

```shell
# 父chart的 requirements.yaml 文件
    ...
    import-values:
      - data
```

```shell
# 子chart的 values.yaml 文件
...
exports:
  data:
    myint: 99
```

```shell
# 父chart的 values 文件
...
myint: 99
```

由于我们在导入列表中指定了键`data`，Helm在子chart的`exports`字段中查找键`data`并导入其内容。

最终的父chart值将包含我们导出的字段：

```shell
# 父chart的 values 文件
...
myint: 99
```

请注意父chart键`data`最终不会包含在父chart值中。如果需要指定父chart键，请使用“子-父”格式。

#### 4.4.2 使用子-父格式

要访问未包含在子chart值的`exports`键中的值，需要指定要导入的值的源键（子）和父chart值的目标路径（父）。

下面示例中的`import-values` 指示Helm获取在`child:`路径上找到的任何值，并将它们复制到父chart `parent:`指定的路径上：

```shell
# parent's requirements.yaml file
dependencies:
  - name: subchart1
    repository: http://localhost:10191
    version: 0.1.0
    ...
    import-values:
      - child: default.data
        parent: myimports
```

在上面的示例中， 在`subchart1`的`values.yaml`中的`default.data`找到的值将被导入到父chart值中的`myimports`键，具体如下：

```shell
# parent's values.yaml file

myimports:
  myint: 0
  mybool: false
  mystring: "helm rocks!"
```

```shell
# subchart1's values.yaml file

default:
  data:
    myint: 999
    mybool: true
```

父chart的值如下

```shell
# parent's final values

myimports:
  myint: 999
  mybool: true
  mystring: "helm rocks!"
```

父chart的最终值现在包含从`subchart1`导入的`myint`和`mybool`字段。

### 4.5 通过charts/目录手动管理依赖

如果需要对依赖项进行更多的控制，可以通过将依赖chart复制到`charts/`目录中来显式地表示这些依赖。

依赖可以是chart归档（`foo-1.2.3.tgz`），也可以是未打包的chart目录。但是它的名字不能以`_`或`.`开头，因为这类文件将被chart加载器忽略。

例如，如果WordPress chart依赖于Apache chart，Apache chart（正确的版本）在WordPress chart的`charts/`目录中提供：

```shell
wordpress:
  Chart.yaml
  requirements.yaml
  # ...
  charts/
    apache/
      Chart.yaml
      # ...
    mysql/
      Chart.yaml
      # ...
```

上面的例子显示了WordPress chart是如何通过在`charts/`目录中包含这些chart来表达它对Apache和MySQL的依赖的。

<table><tr><td bgcolor=lightblue>提示：要将依赖放入charts/目录，请使用helm fetch命令。</td></tr></table>

### 4.6 使用依赖项的可操作方面

上面的章节解释了如何指定chart的依赖关系，但是这对使用`helm install`和`helm upgrade`的chart安装有什么影响呢？

假设一个名为“A”的chart创建了以下Kubernetes对象：

- 命名空间：“A-Namespace”
- StatefulSet：“A-StatefulSet”
- 服务：“A-Service”

此外，A依赖于创建如下对象的chart B：

- 命名空间：“B-Namespace”
- ReplicaSet：“B-ReplicaSet”
- 服务：“B-Service”

安装或升级chart A后，创建或修改一个Helm发布。该发布将按照以下顺序创建或更新上述Kubernetes对象：

- A-Namespace
- B-Namespace
- A-StatefulSet
- B-ReplicaSet
- A-Service
- B-Service

这是因为在Helm安装或升级chart时，chart中的Kubernetes对象及其所有依赖都是：

- 聚合成单个集合；然后
- 按类型和名称排序；然后
- 按此顺序创建或更新。

因此，使用chart及其依赖的所有对象创建一个单独的发布。

Kubernetes类型的安装顺序由`kind_sorter.go`中的枚举`InstallOrder`决定。（参见[Helm源文件](https://github.com/helm/helm/blob/master/pkg/tiller/kind_sorter.go#l26)）。

## 5. 模板与值

Helm Chart模板是用[Go模板语言](https://golang.org/pkg/text/template/)编写的，从[Sprig库](https://github.com/Masterminds/sprig)中添加了大约50个附加模板函数和一些其他的[专用函数](https://helm.sh/docs/developing_charts/#chart-development-tips-and-tricks)。

所有模板文件都存储在chart的`templates/`文件夹中。当Helm渲染chart时，它将通过模板引擎传递该目录中的每个文件。

模板的值有两种提供方式：

- chart开发人员可能会在chart中提供一个名为`values.yaml`的文件。这个文件可以包含默认值。
- chart用户可以提供包含值的YAML文件。这可以在`helm install`的命令行中提供。

当用户提供自定义值时，这些值将覆盖chart的`values.yaml`中的值。

### 5.1 模板文件

模板文件遵循编写Go模板的标准约定（有关详细信息，请参阅[文本/模板Go包文档](https://golang.org/pkg/text/template/)）。一个模板文件的例子可能是这样的：

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: deis-database
  namespace: deis
  labels:
    app.kubernetes.io/managed-by: deis
spec:
  replicas: 1
  selector:
    app.kubernetes.io/name: deis-database
  template:
    metadata:
      labels:
        app.kubernetes.io/name: deis-database
    spec:
      serviceAccount: deis-database
      containers:
        - name: deis-database
          image: {{.Values.imageRegistry}}/postgres:{{.Values.dockerTag}}
          imagePullPolicy: {{.Values.pullPolicy}}
          ports:
            - containerPort: 5432
          env:
            - name: DATABASE_STORAGE
              value: {{default "minio" .Values.storage}}
```

上面的示例松散地基于https://github.com/deis/charts，是Kubernetes副本控制器的模板。它可以使用了以下四个模板值（通常在一个`values.yaml`中定义）：

- `imageRegistry`：Docker镜像的源仓库
- `dockerTag`：Docker镜像的标签（tag）
- `pullPolicy`：Kubernetes的镜像拉取策略
- `storage`：存储后端，默认设置为`"minio"`

所有这些值都是由模板作者定义的。Helm不需要或定义参数。

要查看可工作chart，请查看[Helm Charts项目](https://github.com/helm/charts)。

### 5.2 预定义值

通过`values.yaml`或`--set`选项提供的值可以从模板中的`.Values`对象访问。但是你可以在模板中访问其他预定义的数据片段。

以下值是预先定义的，每个模板都可以使用，并且不能被覆盖。与所有值一样，名称是区分大小写的。

- `Release.Name`：发布的名称（不是chart的名称）

- `Release.Time`：chart发布最后一次更新的时间。这将匹配发布对象上的 `Last Released`时间。

- `Release.Namespace`：chart发布所在的命名空间。

- `Release.Service`：管理发布的服务。通常为`Tiller`。

- `Release.IsUpgrade`：如果当前操作是升级或回滚，则将其设置为`true`。

- `Release.IsInstall`：如果当前操作是安装，则将其设置为`true`。

- `Release.Revision`：修订号。它从1开始，每 `helm upgrade`一次，其值加1。

- `Chart`：`Chart.yaml`的内容，因此，可以通过`Chart.Version`获取chart版本，`Chart.Maintainers`获取维护者。

- `Files`：包含chart中所有非特殊文件的类似于Map的对象。你不能访问模板，但可以访问存在的其他文件（除非使用`.helmignore`排除它们）。可以使用 `{{index .Files "file.name"}}`或使用`{{.Files.Get name}}` 或 `{{.Files.GetString name}}`函数访问文件。你也可以使用 `{{.Files.GetBytes}}`获取文件内容的字节数据（`[]byte`）。

- `Capabilities`：一个类似地图的对象，它包含关于Kubernetes版本（`{{.Capabilities.KubeVersion}}`）、Tiller版本（`{{.Capabilities.TillerVersion}}`）和支持的Kubernetes API版本（`{{.Capabilities.APIVersions.Has "batch/v1"`）信息。

  <table><tr><td bgcolor=lightblue>注意：任何未知的Chart.yaml字段将被删除。它们在Chart对象内部不可访问。因此，Chart.yaml不能用于将任意结构的数据传递到模板中。但是，values.yaml文件可以用于此目的。</td></tr></table>

### 5.3 values.yaml文件

考虑上一节中的模板，一个`values.yaml`文件提供必要的值应该是这样的：

```yaml
imageRegistry: "quay.io/deis"
dockerTag: "latest"
pullPolicy: "Always"
storage: "s3"
```

`values.yaml`文件是YAML格式的。chart可以包含一个提供默认值的`values.yaml`文件。`helm install`命令允许用户通过提供额外的YAML值来覆盖这些值：

```shell
$ helm install --values=myvals.yaml wordpress
```

当以这种方式传递值时，它们将被合并到默认的值（values）文件中。例如，考虑一下`myvals.yaml`文件，看起来像这样：

```yaml
storage: "gcs"
```

当它与`values.yaml`合并时，在chart中，生成的结果内容如下：

```yaml
imageRegistry: "quay.io/deis"
dockerTag: "latest"
pullPolicy: "Always"
storage: "gcs"
```

**注意**，只覆盖了最后一个字段。



<table><tr><td bgcolor=lightblue>注意：chart中包含的默认值文件必须命名为values.yaml。但是在命令行中指定的文件可以命名为任何名称。</td></tr></table>



<table><tr><td bgcolor=lightblue>注意：如果在helm install或helm upgrade时使用了--set选项，那么这些值将在客户端被简单地转换为YAML。</td></tr></table>



<table><tr><td bgcolor=lightblue>注意：如果值（values）文件中存在任何必需的条目，可以使用required函数(https://www.coderdocument.com/docs/helm/v2/charts/intro_to_charts.html)在chart模板中进行声明。</td></tr></table>

这些值中的任何一个都可以在模板中使用`.Values`对象进行访问：

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: deis-database
  namespace: deis
  labels:
    app.kubernetes.io/managed-by: deis
spec:
  replicas: 1
  selector:
    app.kubernetes.io/name: deis-database
  template:
    metadata:
      labels:
        app.kubernetes.io/name: deis-database
    spec:
      serviceAccount: deis-database
      containers:
        - name: deis-database
          image: {{.Values.imageRegistry}}/postgres:{{.Values.dockerTag}}
          imagePullPolicy: {{.Values.pullPolicy}}
          ports:
            - containerPort: 5432
          env:
            - name: DATABASE_STORAGE
              value: {{default "minio" .Values.storage}}

```



### 5.4 范围、依赖与值

值（values）文件可以声明层chart的值，也可以声明包含在该chart的`charts/`目录中的任何chart的值。或者，换句话说，一个`values`文件可以向chart及其任何依赖的chart提供值。例如，上面的演示chart中`mysql`和`apache`都是依赖的chart。值文件可以为所有这些组件提供值：

```yaml
title: "My WordPress Site" # Sent to the WordPress template

mysql:
  max_connections: 100 # Sent to MySQL
  password: "secret"

apache:
  port: 8080 # Passed to Apache
```

更高层次的chart可以访问下层chart定义的所有变量。因此WordPress chart可以通过 `.Values.mysql.password`访问MySQL密码。但是下层chart不能访问父chart中的内容，所以MySQL chart将不能访问`title`属性。同样，它也不能访问`apache.port`。

值是命名空间范围的，但名称空间被修剪。因此，对于WordPress chart，它可以通过 `.Values.mysql.password`访问MySQL密码字段。但是对于MySQL chart，值的作用域被缩小了，命名空间前缀被移除了，所以它会将`password`字段简单地看作 `.Values.password`。

#### 5.4.1 全局值（value）

从2.0.0-Alpha.2开始，Helm支持特殊的“全局”值。考虑前面例子的修改版本：

```yaml
title: "My WordPress Site" # Sent to the WordPress template

global:
  app: MyWordPress

mysql:
  max_connections: 100 # Sent to MySQL
  password: "secret"

apache:
  port: 8080 # Passed to Apache
```

上面添加了一个拥有 `app: MyWordPress`值的全局部分。此值可通过 `.Values.global.app`用于*所有*chart。

例如，`mysql`模板可以以`{{.Values.global.app}}`的形式访问`app`， `apache` chart也可以使用。实际上，上面的值文件是这样重新生成的：

```yaml
title: "My WordPress Site" # Sent to the WordPress template

global:
  app: MyWordPress

mysql:
  global:
    app: MyWordPress
  max_connections: 100 # Sent to MySQL
  password: "secret"

apache:
  global:
    app: MyWordPress
  port: 8080 # Passed to Apache
```

这提供了一种与所有子chart共享一个顶层变量的方法，这对于设置标签等`metadata`属性非常有用。

如果子chart声明了一个全局变量，那么该全局变量将向下传递（传递到子chart的子chart），而不是向上传递到父chart。子chart无法影响父chart的值。

此外，父chart的全局变量优先于子chart的全局变量。

### 5.5 参考

在编写模板和值文件时，有几个标准参考可以帮助你。

- [Go模板](https://godoc.org/text/template)
- [其它模板函数](https://godoc.org/github.com/Masterminds/sprig)
- [YAML格式](https://yaml.org/spec/)

## 6. 使用Helm管理chart

`helm`工具有几个处理chart的命令。

```shell
# 它可以为你创建一个新的chart：
$ helm create mychart
Created mychart/
```

```shell
# 一旦你已经编辑了一个chart，helm可以为你把它打包成一个chart归档：
$ helm package mychart
Archived mychart-0.1.-.tgz
```

```shell
# 你也可以使用helm来帮助你发现chart格式或信息方面的问题：
$ helm lint mychart
No issues found
```



## 7. chart仓库

​		chart仓库是一个HTTP服务器，其中存放一个或多个打包的chart。虽然`helm`可用于管理本地chart目录，但在共享chart时，首选的机制是chart仓库。

​		任何能够提供YAML文件和tar文件并能够响应GET请求的HTTP服务器都可以作为仓库服务器。

​		Helm自带用于开发人员测试的内置包服务器（`helm serve`）。Helm团队已经测试了其他服务器，包括启用了网站模式的谷歌云存储和启用了网站模式的S3。

​		仓库的主要特征是存在一个称为`index.yaml`的特殊文件，该文件包含仓库提供的所有包的列表，以及允许检索和验证这些包的元数据。

​		在客户端，仓库由`helm repo`命令管理。但是，Helm不提供将chart上传到远程仓库服务器的工具。这是因为这样做会给实现服务器增加大量的要求，从而增加了设置仓库的障碍。

## 8. chart入门包

`	helm create`命令接受一个可选的`--starter`选项，该选项允许你指定一个“启动器chart”。

启动器只是普通的chart，但位于`$HELM_HOME/starters`。作为chart开发人员，你可以编写专门用于启动器的chart。这种chart的设计应考虑到下列因素：

- `Chart.yaml`将被生成器覆盖。
- 用户将期望修改这样一个chart的内容，因此文档应该说明用户可以如何修改。
- `templates`目录中文件中出现的所有`<CHARTNAME>`都将被替换为指定的chart名称，以便启动器chart可以用作模板。此外， `values.yaml`中的`<CHARTNAME>`也将被替换。

目前，向`$HELM_HOME/starters`添加chart的唯一方法是手动复制。在chart的文档中，你可能需要解释这个过程。