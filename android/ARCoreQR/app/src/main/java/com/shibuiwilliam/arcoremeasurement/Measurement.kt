package com.shibuiwilliam.arcoremeasurement

import android.annotation.SuppressLint
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.app.Activity
import android.app.ActivityManager
import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.*
import com.google.ar.core.*
import com.google.ar.sceneform.AnchorNode
import com.google.ar.sceneform.FrameTime
import com.google.ar.sceneform.Node
import com.google.ar.sceneform.Scene
import com.google.ar.sceneform.math.Vector3
import com.google.ar.sceneform.rendering.*
import com.google.ar.sceneform.ux.ArFragment
import com.google.ar.sceneform.ux.TransformableNode
import com.google.ar.sceneform.rendering.Color as arColor
import java.util.Objects
import kotlin.math.pow
import kotlin.math.sqrt

import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*

import android.Manifest
import android.content.pm.PackageManager
import android.widget.Toast

import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import android.media.Image
import com.google.ar.core.exceptions.NotYetAvailableException

import java.io.ByteArrayOutputStream
import android.graphics.Bitmap
import android.graphics.YuvImage
import android.graphics.Rect
import android.graphics.BitmapFactory
import android.graphics.Matrix
import com.google.ar.core.Config
import android.util.DisplayMetrics


class Measurement : AppCompatActivity(), Scene.OnUpdateListener {
    private val MIN_OPENGL_VERSION = 3.0
    private val TAG: String = Measurement::class.java.getSimpleName()

    private var arFragment: ArFragment? = null

    private var distanceModeTextView: TextView? = null

    private lateinit var multipleDistanceTableLayout: TableLayout

    private var cubeRenderable: ModelRenderable? = null
    private var distanceCardViewRenderable: ViewRenderable? = null

    private lateinit var distanceModeSpinner: Spinner
    private val distanceModeArrayList = ArrayList<String>()
    private var distanceMode: String = ""

    private val placedAnchors = ArrayList<Anchor>()
    private val placedAnchorNodes = ArrayList<AnchorNode>()
    private val midAnchors: MutableMap<String, Anchor> = mutableMapOf()
    private val midAnchorNodes: MutableMap<String, AnchorNode> = mutableMapOf()
    private val fromGroundNodes = ArrayList<List<Node>>()

    private val multipleDistances = Array(Constants.maxNumMultiplePoints,
        {Array<TextView?>(Constants.maxNumMultiplePoints){null} })
    private lateinit var initCM: String

    private lateinit var clearButton: Button
    private lateinit var scanButton: Button
    private lateinit var startButton: Button
    private lateinit var stopButton: Button

    private var isAnchorPlaced = false
    private var isScanning = true
    private var isRecording = false
    private var csvWriter: FileWriter? = null
    private val placedWorldCoordinates = mutableListOf<FloatArray>()


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!checkIsSupportedDeviceOrFinish(this)) {
            Toast.makeText(applicationContext, "Device not supported", Toast.LENGTH_LONG)
                .show()
        }
        setContentView(R.layout.activity_measurement)
        val distanceModeArray = resources.getStringArray(R.array.distance_mode)
        distanceModeArray.map { it ->
            distanceModeArrayList.add(it)
        }
        arFragment = supportFragmentManager.findFragmentById(R.id.sceneform_fragment) as ArFragment?
        distanceModeTextView = findViewById(R.id.distance_view)
        multipleDistanceTableLayout = findViewById(R.id.multiple_distance_table)

        initCM = resources.getString(R.string.initCM)

        configureSpinner()
        initRenderable()
        clearButton()
        setupStartButton()
        setupStopButton()

        if (allPermissionsGranted()) {
            setupArSceneView()
        } else {
            ActivityCompat.requestPermissions(
                this, REQUIRED_PERMISSIONS, REQUEST_CODE_PERMISSIONS
            )
        }
    }

    override fun onResume() {
        super.onResume()
        setupArSceneView()
    }

    private fun allPermissionsGranted() = REQUIRED_PERMISSIONS.all {
        ContextCompat.checkSelfPermission(
            baseContext, it
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun setupArSceneView() {
        val rotationDegrees = 90
        val session = arFragment?.arSceneView?.session ?: Session(this)
        val config = Config(session).apply {
            focusMode = Config.FocusMode.AUTO
            updateMode = Config.UpdateMode.LATEST_CAMERA_IMAGE
            instantPlacementMode = Config.InstantPlacementMode.LOCAL_Y_UP
        }

        session.configure(config)
        session.resume()
        session.pause()
        session.resume()

        arFragment!!.arSceneView.setupSession(session)

        arFragment!!.arSceneView.scene.addOnUpdateListener { frameTime ->
            if (isScanning) {
                isScanning = false

                val frame = session.update()
                try {
                    val image = frame.acquireCameraImage()
                    val bitmap = imageToBitmap(image, rotationDegrees)
                    val inputImage = InputImage.fromBitmap(bitmap, rotationDegrees)
                    val scanner = BarcodeScanning.getClient()

                    scanner.process(inputImage)
                        .addOnSuccessListener { barcodes ->
                            if (barcodes.isEmpty()) {
                                Log.d(TAG, "No barcodes found")
                                isScanning = true
                            } else {
                                for (barcode in barcodes) {
                                    val bounds = barcode.boundingBox
                                    val rawValue = barcode.rawValue

                                    if (bounds != null) {
                                        val cameraWidth = 480
                                        val cameraHeight = 640
                                        val (screenWidth, screenHeight) = getScreenResolution()
                                        val scaleY = screenHeight.toFloat() / cameraHeight.toFloat()

                                        val boxcenterX = ((bounds.bottom + bounds.top) / 2).toFloat()
                                        val boxcenterY = ((bounds.left + bounds.right) / 2).toFloat()
                                        val centerX = boxcenterX * scaleY - (cameraWidth * scaleY - screenWidth) / 2
                                        val centerY = screenHeight - boxcenterY * scaleY

                                        val approximateDistanceMeters = 2.0f // keep default
                                        val frame = session.update()
                                        val results = frame.hitTestInstantPlacement(centerX, centerY, approximateDistanceMeters)
                                        if (results.isNotEmpty()) {
                                            Log.d(TAG, "Hit tested, results size: ${results.size}")

                                            val hitResult = results[0]
                                            val anchor = hitResult.createAnchor()

                                            val anchorNode = AnchorNode(anchor).apply {
                                                setParent(arFragment?.arSceneView?.scene)
                                            }

                                            placedAnchorNodes.add(anchorNode)
                                            placeAnchor(hitResult, distanceCardViewRenderable!!)

                                            val anchorPose = anchor.pose
                                            val worldCoordinates = FloatArray(3).apply {
                                                anchorPose.getTranslation(this, 0)
                                            }

                                            placedWorldCoordinates.add(worldCoordinates)

                                            runOnUiThread {
                                                val coordinatesString = "x: ${worldCoordinates[0]}, y: ${worldCoordinates[1]}, z: ${worldCoordinates[2]}"
                                                Toast.makeText(this@Measurement, coordinatesString, Toast.LENGTH_SHORT).show()
                                            }

                                            Log.d(TAG, "Anchor placed successfully.")
                                        } else {
                                            Log.d(TAG, "Hit test failed.")
                                            isScanning = true
                                        }
                                    } else {
                                        Log.d(TAG, "Bounding box is null")
                                        isScanning = true
                                    }
                                }
                            }
                        }
                        .addOnFailureListener { e ->
                            Log.e(TAG, "Barcode processing failed", e)
                            isScanning = true
                        }
                    image.close()
                } catch (e: NotYetAvailableException) {
                    Log.e(TAG, "Camera image not yet available", e)
                    isScanning = true
                }
            }
        }
    }

    private fun getScreenResolution(): Pair<Int, Int> {
        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels
        return Pair(screenWidth, screenHeight)
    }

    private fun setupStartButton() {
        startButton = findViewById(R.id.start_button)
        startButton.setOnClickListener {
            if (!isRecording) {
                val sdf = SimpleDateFormat("yyMMdd_HHmmss", Locale.getDefault())
                val currentDateTime = sdf.format(Date())
                val fileName = "experiment_$currentDateTime.csv"
                val file = File(getExternalFilesDir(null), fileName)
                csvWriter = FileWriter(file)
                csvWriter?.append("Timestamp,Distance,DirectionX,DirectionY,DirectionZ\n")
                isRecording = true
                Toast.makeText(this, "Start CSV recording", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun setupStopButton() {
        stopButton = findViewById(R.id.stop_button)
        stopButton.setOnClickListener {
            if (isRecording) {
                csvWriter?.flush()
                csvWriter?.close()
                isRecording = false
                Toast.makeText(this, "Finish CSV recording", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun imageToBitmap(image: Image, rotationDegrees: Int): Bitmap {
        val data = imageToByteArray(image)
        val bitmap = BitmapFactory.decodeByteArray(data, 0, data.size)
        return if (rotationDegrees != 0) {
            rotateBitmap(bitmap, rotationDegrees)
        } else {
            bitmap
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, rotationDegrees: Int): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(rotationDegrees.toFloat())
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun imageToByteArray(image: Image): ByteArray {
        return when (image.format) {
            ImageFormat.YUV_420_888 -> {
                NV21toJPEG(YUV_420_888toNV21(image), image.width, image.height)
            }
            else -> throw IllegalArgumentException("Unsupported image format: ${image.format}")
        }
    }

    private fun YUV_420_888toNV21(image: Image): ByteArray {
        val nv21: ByteArray
        val yBuffer = image.planes[0].buffer
        val uBuffer = image.planes[1].buffer
        val vBuffer = image.planes[2].buffer
        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()
        nv21 = ByteArray(ySize + uSize + vSize)
        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)
        return nv21
    }

    private fun NV21toJPEG(nv21: ByteArray, width: Int, height: Int): ByteArray {
        val out = ByteArrayOutputStream()
        val yuv = YuvImage(nv21, android.graphics.ImageFormat.NV21, width, height, null)
        yuv.compressToJpeg(Rect(0, 0, width, height), 100, out)
        return out.toByteArray()
    }

    companion object {
        private const val TAG = "QRScanner"
        private const val REQUEST_CODE_PERMISSIONS = 10
        private val REQUIRED_PERMISSIONS = arrayOf(Manifest.permission.CAMERA)
    }

    private fun initDistanceTable(){
        for (i in 0 until Constants.maxNumMultiplePoints+1){
            val tableRow = TableRow(this)
            multipleDistanceTableLayout.addView(tableRow,
                multipleDistanceTableLayout.width,
                Constants.multipleDistanceTableHeight / (Constants.maxNumMultiplePoints + 1))
            for (j in 0 until Constants.maxNumMultiplePoints+1){
                val textView = TextView(this)
                textView.setTextColor(Color.WHITE)
                if (i==0){
                    if (j==0){
                        textView.setText("cm")
                    }
                    else{
                        textView.setText((j-1).toString())
                    }
                }
                else{
                    if (j==0){
                        textView.setText((i-1).toString())
                    }
                    else if(i==j){
                        textView.setText("-")
                        multipleDistances[i-1][j-1] = textView
                    }
                    else{
                        textView.setText(initCM)
                        multipleDistances[i-1][j-1] = textView
                    }
                }
                tableRow.addView(textView,
                    tableRow.layoutParams.width / (Constants.maxNumMultiplePoints + 1),
                    tableRow.layoutParams.height)
            }
        }
    }

    private fun initRenderable() {
        MaterialFactory.makeTransparentWithColor(
            this,
            arColor(Color.RED))
            .thenAccept { material: Material? ->
                cubeRenderable = ShapeFactory.makeSphere(
                    0.02f,
                    Vector3.zero(),
                    material)
                cubeRenderable!!.setShadowCaster(false)
                cubeRenderable!!.setShadowReceiver(false)
            }
            .exceptionally {
                val builder = AlertDialog.Builder(this)
                builder.setMessage(it.message).setTitle("Error")
                val dialog = builder.create()
                dialog.show()
                return@exceptionally null
            }

        ViewRenderable
            .builder()
            .setView(this, R.layout.distance_text_layout)
            .build()
            .thenAccept{
                distanceCardViewRenderable = it
                distanceCardViewRenderable!!.isShadowCaster = false
                distanceCardViewRenderable!!.isShadowReceiver = false
            }
            .exceptionally {
                val builder = AlertDialog.Builder(this)
                builder.setMessage(it.message).setTitle("Error")
                val dialog = builder.create()
                dialog.show()
                return@exceptionally null
            }
    }

    private fun configureSpinner(){
        distanceMode = distanceModeArrayList[0]
        distanceModeSpinner = findViewById(R.id.distance_mode_spinner)
        val distanceModeAdapter = ArrayAdapter(
            applicationContext,
            android.R.layout.simple_spinner_item,
            distanceModeArrayList
        )
        distanceModeAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        distanceModeSpinner.adapter = distanceModeAdapter
        distanceModeSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener{
            override fun onItemSelected(parent: AdapterView<*>?,
                                        view: View?,
                                        position: Int,
                                        id: Long) {
                val spinnerParent = parent as Spinner
                distanceMode = spinnerParent.selectedItem as String
                clearAllAnchors()
                setMode()
                toastMode()
                if (distanceMode == distanceModeArrayList[2]){
                    val layoutParams = multipleDistanceTableLayout.layoutParams
                    layoutParams.height = Constants.multipleDistanceTableHeight
                    multipleDistanceTableLayout.layoutParams = layoutParams
                    initDistanceTable()
                }
                else{
                    val layoutParams = multipleDistanceTableLayout.layoutParams
                    layoutParams.height = 0
                    multipleDistanceTableLayout.layoutParams = layoutParams
                }
                Log.i(TAG, "Selected arcore focus on ${distanceMode}")
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {
                clearAllAnchors()
                setMode()
                toastMode()
            }
        }
    }

    private fun setMode(){
        distanceModeTextView!!.text = distanceMode
    }

    private fun clearButton(){
        clearButton = findViewById(R.id.clearButton)
        clearButton.setOnClickListener(object: View.OnClickListener {
            override fun onClick(v: View?) {
                clearAllAnchors()
            }
        })
    }

    private fun clearAllAnchors(){
        placedAnchors.clear()
        for (anchorNode in placedAnchorNodes){
            arFragment!!.arSceneView.scene.removeChild(anchorNode)
            anchorNode.isEnabled = false
            anchorNode.anchor!!.detach()
            anchorNode.setParent(null)
        }
        placedAnchorNodes.clear()
        midAnchors.clear()
        for ((k,anchorNode) in midAnchorNodes){
            arFragment!!.arSceneView.scene.removeChild(anchorNode)
            anchorNode.isEnabled = false
            anchorNode.anchor!!.detach()
            anchorNode.setParent(null)
        }
        midAnchorNodes.clear()
        for (i in 0 until Constants.maxNumMultiplePoints){
            for (j in 0 until Constants.maxNumMultiplePoints){
                if (multipleDistances[i][j] != null){
                    multipleDistances[i][j]!!.setText(if(i==j) "-" else initCM)
                }
            }
        }
        fromGroundNodes.clear()
    }

    private fun placeAnchor(hitResult: HitResult,
                            renderable: Renderable){
        val anchor = hitResult.createAnchor()
        placedAnchors.add(anchor)

        val anchorNode = AnchorNode(anchor).apply {
            isSmoothed = true
            setParent(arFragment!!.arSceneView.scene)
        }
        placedAnchorNodes.add(anchorNode)

        val node = TransformableNode(arFragment!!.transformationSystem)
            .apply{
                this.rotationController.isEnabled = false
                this.scaleController.isEnabled = false
                this.translationController.isEnabled = true
                this.renderable = renderable
                setParent(anchorNode)
            }

        arFragment!!.arSceneView.scene.addOnUpdateListener(this)
        arFragment!!.arSceneView.scene.addChild(anchorNode)
        node.select()
    }

    @SuppressLint("SetTextI18n")
    override fun onUpdate(frameTime: FrameTime) {
        when(distanceMode) {
            distanceModeArrayList[0] -> {
                measureDistanceFromCamera()
            }
            else -> {
                measureDistanceFromCamera()
            }
        }
    }

    private fun measureDistanceFromCamera() {
        val frame = arFragment!!.arSceneView.arFrame
        if (!isScanning && isRecording) {

            // Anchor 3D coordinates from saved world coordinates
            val worldCoordinates = placedWorldCoordinates[0]
            val anchorPose = Pose.makeTranslation(worldCoordinates[0], worldCoordinates[1], worldCoordinates[2])

            // Current device 3D pose
            val devicePose = frame!!.androidSensorPose
            val inverseDevicePose = devicePose.inverse()

            // Relative pose between device and anchor
            val relativePose = inverseDevicePose.compose(anchorPose)
            val relativeTranslation = relativePose.translation
            val x = -relativeTranslation[0]
            val y = -relativeTranslation[1]
            val z = -relativeTranslation[2]

            Log.d("RelativePose", "Relative Pose: x=$x, y=$y, z=$z")

            // Calculate distance (using Pose translations directly)
            val distanceMeter = Math.sqrt(
                Math.pow((worldCoordinates[0] - devicePose.tx()).toDouble(), 2.0) +
                        Math.pow((worldCoordinates[1] - devicePose.ty()).toDouble(), 2.0) +
                        Math.pow((worldCoordinates[2] - devicePose.tz()).toDouble(), 2.0)
            ).toFloat()

            measureDistanceOf2Points(distanceMeter)

            // Log the data
            val timestamp = System.currentTimeMillis() / 1000
            csvWriter?.append("$timestamp,$distanceMeter,$x,$y,$z\n")
        }
    }

    private fun logAnchorOrientation(anchor: Anchor) {
        val pose = anchor.pose
        
        val xAxis = pose.getTransformedAxis(0, 1.0f)
        val yAxis = pose.getTransformedAxis(1, 1.0f)
        val zAxis = pose.getTransformedAxis(2, 1.0f)

        Log.d(TAG, "Anchor Orientation - X: (${xAxis[0]}, ${xAxis[1]}, ${xAxis[2]})")
        Log.d(TAG, "Anchor Orientation - Y: (${yAxis[0]}, ${yAxis[1]}, ${yAxis[2]})")
        Log.d(TAG, "Anchor Orientation - Z: (${zAxis[0]}, ${zAxis[1]}, ${zAxis[2]})")
    }


    private fun measureDistanceOf2Points(distanceMeter: Float){
        val distanceTextCM = makeDistanceTextWithCM(distanceMeter)
        val textView = (distanceCardViewRenderable!!.view as LinearLayout)
            .findViewById<TextView>(R.id.distanceCard)
        textView.text = distanceTextCM
        Log.d(TAG, "distance: ${distanceTextCM}")
    }


    private fun makeDistanceTextWithCM(distanceMeter: Float): String{
        val distanceCM = changeUnit(distanceMeter, "cm")
        val distanceCMFloor = "%.2f".format(distanceCM)
        return "${distanceCMFloor} cm"
    }

    private fun calculateDistance(x: Float, y: Float, z: Float): Float{
        return sqrt(x.pow(2) + y.pow(2) + z.pow(2))
    }

    private fun calculateDistance(objectPose0: Vector3, objectPose1: Pose): Float{
        return calculateDistance(
            objectPose0.x - objectPose1.tx(),
            objectPose0.y - objectPose1.ty(),
            objectPose0.z - objectPose1.tz()
        )
    }

    private fun changeUnit(distanceMeter: Float, unit: String): Float{
        return when(unit){
            "cm" -> distanceMeter * 100
            "mm" -> distanceMeter * 1000
            else -> distanceMeter
        }
    }

    private fun toastMode(){
        Toast.makeText(this@Measurement,
            when(distanceMode){
                distanceModeArrayList[0] -> "Find plane and tap somewhere"
                distanceModeArrayList[1] -> "Find plane and tap 2 points"
                distanceModeArrayList[2] -> "Find plane and tap multiple points"
                distanceModeArrayList[3] -> "Find plane and tap point"
                else -> "???"
            },
            Toast.LENGTH_LONG)
            .show()
    }


    private fun checkIsSupportedDeviceOrFinish(activity: Activity): Boolean {
        val openGlVersionString =
            (Objects.requireNonNull(activity
                .getSystemService(Context.ACTIVITY_SERVICE)) as ActivityManager)
                .deviceConfigurationInfo
                .glEsVersion
        if (openGlVersionString.toDouble() < MIN_OPENGL_VERSION) {
            Log.e(TAG, "Sceneform requires OpenGL ES ${MIN_OPENGL_VERSION} later")
            Toast.makeText(activity,
                "Sceneform requires OpenGL ES ${MIN_OPENGL_VERSION} or later",
                Toast.LENGTH_LONG)
                .show()
            activity.finish()
            return false
        }
        return true
    }
}